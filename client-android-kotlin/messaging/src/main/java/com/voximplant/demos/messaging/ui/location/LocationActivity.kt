package com.voximplant.demos.messaging.ui.location

import android.Manifest.permission.ACCESS_FINE_LOCATION
import android.content.Intent
import android.content.Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.os.Bundle
import android.os.Looper
import android.view.MenuItem
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.view.isVisible
import com.google.android.gms.location.*
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MarkerOptions
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.ui.activeConversation.ActiveConversationActivity
import com.voximplant.demos.messaging.utils.ifNull
import kotlinx.android.synthetic.main.activity_location.*

private typealias CheckPermissionsCallback = (Boolean) -> Unit

class LocationActivity : AppCompatActivity(), OnMapReadyCallback,
    ActivityCompat.OnRequestPermissionsResultCallback {

    private var map: GoogleMap? = null
    private var isZoomed: Boolean = false
    private val defaultMapScale: Float = 15.0f

    private val sharedLocation: LatLng?
    get() {
        val lat = intent.getDoubleExtra(LATITUDE, 0.0).takeIf { it != 0.0 }.ifNull { return null }
        val lon = intent.getDoubleExtra(LONGITUDE, 0.0).takeIf { it != 0.0 }.ifNull { return null }
        return LatLng(lat, lon)
    }
    private var pickedLocation: LatLng? = null
    private var currentLocation: LatLng? = null

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback
    private lateinit var locationRequest: LocationRequest

    private val permissionsGranted: Boolean
        get() = ContextCompat.checkSelfPermission(this, ACCESS_FINE_LOCATION) == PERMISSION_GRANTED
    private var checkPermissionsCallback: CheckPermissionsCallback? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_location)

        val mapFragment = supportFragmentManager.findFragmentById(R.id.map) as SupportMapFragment
        mapFragment.getMapAsync(this)

        title = if (sharedLocation != null) {
            "Shared location"
        } else {
            "Share location"
        }

        share_location_button.setOnClickListener {
            val location = pickedLocation ?: currentLocation ?: return@setOnClickListener
            shareAndDestroy(location.latitude, location.longitude)
        }

        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                super.onLocationResult(locationResult)

                val location = locationResult.lastLocation.ifNull { return }
                val locationLatLng = LatLng(location.latitude, location.longitude)

                currentLocation = locationLatLng

                if (isZoomed) { return }

                if (sharedLocation == null) {
                    map?.animateCamera(CameraUpdateFactory.newLatLngZoom(locationLatLng, defaultMapScale))
                    map?.addMarker(
                        MarkerOptions()
                            .position(locationLatLng)
                            .title("Share this location")
                            .draggable(false)
                    )
                }

                isZoomed = true
            }
        }

        locationRequest = LocationRequest()
        locationRequest.interval = 12 * 1000
        locationRequest.fastestInterval = 4 * 1000
        locationRequest.priority = LocationRequest.PRIORITY_BALANCED_POWER_ACCURACY

        checkPermissions {
            map?.isMyLocationEnabled = it
        }
    }

    private fun checkPermissions(completion: CheckPermissionsCallback) {
        if (permissionsGranted) {
            completion(true)
        } else {
            requestPermissions(completion)
        }
    }

    private fun requestPermissions(completion: CheckPermissionsCallback) {
        ActivityCompat.requestPermissions(this, arrayOf(ACCESS_FINE_LOCATION),0)
        checkPermissionsCallback = completion
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (grantResults.isNotEmpty()) {
            for (i in permissions.indices) {
                if (permissions[i] == ACCESS_FINE_LOCATION) {
                    checkPermissionsCallback?.invoke(grantResults[i] == PERMISSION_GRANTED)
                }
            }
        }
    }

    override fun onPause() {
        super.onPause()

        fusedLocationClient.removeLocationUpdates(locationCallback)
    }

    override fun onResume() {
        super.onResume()

        if (permissionsGranted) {
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.myLooper()
            )
        }
    }

    override fun onMapReady(googleMap: GoogleMap) {
        map = googleMap

        map?.isMyLocationEnabled = permissionsGranted

        share_location_button.isEnabled = sharedLocation == null
        share_location_button.isVisible = sharedLocation == null

        sharedLocation?.let {
            showLocation(it, "Shared location")
        }
            ?: map?.setOnMapClickListener {
                showLocation(it, "Share this location")
                pickedLocation = it
            }
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when (item.itemId) {
            android.R.id.home -> {
                val intent = Intent(this,  ActiveConversationActivity::class.java)
                intent.flags = FLAG_ACTIVITY_REORDER_TO_FRONT
                startActivity(intent)
                finish()
                return true
            }
        }
        return super.onOptionsItemSelected(item)
    }

    private fun showLocation(location: LatLng, title: String) {
        map?.clear()
        map?.addMarker(
            MarkerOptions()
                .position(location)
                .title(title)
                .draggable(false)
        )
        map?.animateCamera(CameraUpdateFactory.newLatLngZoom(location, defaultMapScale))
    }

    private fun shareAndDestroy(latitude: Double, longitude: Double) {
        val intent = Intent(this,  ActiveConversationActivity::class.java)
        intent.flags = FLAG_ACTIVITY_REORDER_TO_FRONT
        intent.putExtra(LATITUDE, latitude)
        intent.putExtra(LONGITUDE, longitude)
        startActivity(intent)
        finish()
    }

    companion object {
        const val LATITUDE = "latitude"
        const val LONGITUDE = "longitude"
    }
}
