package com.voximplant.demos.messaging.ui.activeConversation

import android.view.View
import androidx.core.view.isVisible
import androidx.recyclerview.widget.RecyclerView
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.MapsInitializer
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MarkerOptions
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.ui.activeConversation.MessengerEventModel.*
import com.voximplant.demos.messaging.utils.getDrawableById
import com.voximplant.demos.messaging.utils.ifNull
import kotlinx.android.synthetic.main.active_conversation_event_adapter_row.view.*
import kotlinx.android.synthetic.main.active_conversation_location_adapter_row.view.*
import kotlinx.android.synthetic.main.active_conversation_message_adapter_row.view.*
import kotlinx.android.synthetic.main.active_conversation_message_adapter_row.view.message_sender_text_view
import kotlinx.android.synthetic.main.active_conversation_my_location_adapter_row.view.*
import kotlinx.android.synthetic.main.active_conversation_my_location_adapter_row.view.map_preview
import kotlinx.android.synthetic.main.active_conversation_my_message_adapter_row.view.*
import kotlinx.android.synthetic.main.active_conversation_my_message_adapter_row.view.is_read_image_view


interface ActiveConversationViewHolderListener {
    fun onViewLongTap(view: View, viewPosition: Int)
    fun onViewTap(view: View, viewPosition: Int)
}

class ActiveConversationMessageViewHolder(
    itemView: View,
    private var listener: ActiveConversationViewHolderListener
) : RecyclerView.ViewHolder(itemView), View.OnLongClickListener {

    init {
        itemView.setOnLongClickListener(this)
    }

    fun bind(model: MessageCellModel) {
        itemView.message_text_view.text = model.text
        itemView.message_sender_text_view.text = model.senderName
        itemView.edited_text_view.isVisible = model.isEdited
        itemView.message_time_text_view.text = model.time
    }

    override fun onLongClick(view: View): Boolean {
        listener.onViewLongTap(itemView, adapterPosition)
        return true
    }
}

class ActiveConversationMyMessageViewHolder(
    itemView: View,
    private var listener: ActiveConversationViewHolderListener
) : RecyclerView.ViewHolder(itemView), View.OnLongClickListener {

    init {
        itemView.setOnLongClickListener(this)
    }

    fun bind(model: MessageCellModel) {
        itemView.my_message_text_view.text = model.text
        itemView.my_message_time_text_view.text = model.time
        itemView.my_edited_text_view.isVisible = model.isEdited
        itemView.is_read_image_view.setImageDrawable(
            if (model.isRead) {
                itemView.context.getDrawableById(R.drawable.ic_doublecheck)
            } else {
                itemView.context.getDrawableById(R.drawable.ic_checkmark)
            }
        )
    }

    override fun onLongClick(view: View): Boolean {
        listener.onViewLongTap(itemView, adapterPosition)
        return true
    }
}

class ActiveConversationMyLocationViewHolder(
    itemView: View,
    private val listener: ActiveConversationViewHolderListener
) : RecyclerView.ViewHolder(itemView), View.OnLongClickListener, OnMapReadyCallback {

    private var map: GoogleMap? = null
    private var location: LatLng? = null

    init {
        itemView.setOnLongClickListener(this)

        val mapView = itemView.map_preview
        if (mapView != null) {
            mapView.onCreate(null)
            mapView.getMapAsync(this)
            mapView.onResume()
        }
    }

    fun bind(model: LocationCellModel) {
        itemView.my_location_message_time_text_view.text = model.time
        itemView.is_read_image_view.setImageDrawable(
            if (model.isRead) {
                itemView.context.getDrawableById(R.drawable.ic_doublecheck)
            } else {
                itemView.context.getDrawableById(R.drawable.ic_checkmark)
            }
        )
        location = model.location
        setMapLocation()
    }

    override fun onLongClick(v: View?): Boolean {
        listener.onViewLongTap(itemView, adapterPosition)
        return true
    }

    override fun onMapReady(googleMap: GoogleMap) {
        MapsInitializer.initialize(itemView.context)
        map = googleMap
        map?.uiSettings?.setAllGesturesEnabled(false)
        setMapLocation()
    }

    private fun setMapLocation() {
        val map = map.ifNull { return }

        val location = location.ifNull { return }

        map.clear()
        map.moveCamera(CameraUpdateFactory.newLatLngZoom(location, 13f))
        map.addMarker(MarkerOptions().position(location))

        map.setOnMapClickListener {
            listener.onViewTap(itemView, adapterPosition)
        }

        map.mapType = GoogleMap.MAP_TYPE_NORMAL
    }
}

class ActiveConversationLocationViewHolder(
    itemView: View,
    private val listener: ActiveConversationViewHolderListener
) : RecyclerView.ViewHolder(itemView), View.OnLongClickListener, OnMapReadyCallback {

    private var map: GoogleMap? = null
    private var location: LatLng? = null

    init {
        itemView.setOnLongClickListener(this)

        val mapView = itemView.map_preview
        if (mapView != null) {
            mapView.onCreate(null)
            mapView.getMapAsync(this)
            mapView.onResume()
        }
    }

    fun bind(model: LocationCellModel) {
        itemView.location_message_time_text_view.text = model.time
        itemView.message_sender_text_view.text = model.senderName
        location = model.location
        setMapLocation()
    }

    override fun onLongClick(v: View?): Boolean {
        listener.onViewLongTap(itemView, adapterPosition)
        return true
    }

    override fun onMapReady(googleMap: GoogleMap) {
        MapsInitializer.initialize(itemView.context)
        map = googleMap
        map?.uiSettings?.setAllGesturesEnabled(false)
        setMapLocation()
    }

    private fun setMapLocation() {
        val map = map.ifNull { return }

        val location = location.ifNull { return }

        map.clear()
        map.moveCamera(CameraUpdateFactory.newLatLngZoom(location, 13f))
        map.addMarker(MarkerOptions().position(location))

        map.setOnMapClickListener {
            listener.onViewTap(itemView, adapterPosition)
        }

        map.mapType = GoogleMap.MAP_TYPE_NORMAL
    }
}

class ActiveConversationEventViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {

    private val eventTextView = itemView.event_text_view

    private var eventText: String?
        get() = eventTextView.text.toString()
        set(value) {
            eventTextView.text = value
        }

    fun bind(model: EventCellModel) {
        eventText = model.text
    }
}