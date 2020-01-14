package com.voximplant.demos.messaging.utils

import android.content.Intent
import android.os.Bundle
import android.view.ViewGroup
import android.view.WindowManager
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.Observer
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.ViewModelStoreOwner
import com.voximplant.demos.messaging.ui.login.LoginActivity

abstract class BaseActivity<T : BaseViewModel>(private val modelType: Class<T>) :
    AppCompatActivity() {

    protected val rootViewGroup: ViewGroup
        get() = window.decorView.rootView as ViewGroup

    private var progressHUDView: ProgressHUDView? = null
    private var errorHUDView: AlertDialog? = null

    protected val model: T
        get() = ViewModelProvider(ViewModelStoreOwner { this.viewModelStore }).get(modelType)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        model.showProgress.observe(this, Observer { textID ->
            showProgressHUD(resources.getString(textID))
        })

        model.hideProgress.observe(this, Observer {
            hideProgressHUD()
        })

        model.stringError.observe(this, Observer { text ->
            showError(text)
        })

        model.intError.observe(this, Observer { textID ->
            showError(resources.getString(textID))
        })

        model.subtitle.observe(this, Observer {
            supportActionBar?.subtitle = it
        })

        model.finish.observe(this, Observer {
            finish()
        })

        model.showLogin.observe(this, Observer {
            val intent = Intent(applicationContext, LoginActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK)
            startActivity(intent)
        })

        model.showConnectionError.observe(this, Observer {
            showConnectionError(it)
        })

        model.onCreate()
    }

    override fun onResume() {
        super.onResume()

        model.onResume()
    }

    override fun onDestroy() {
        super.onDestroy()

        model.onDestroy()
    }

    fun showProgressHUD(text: String) {
        runOnUiThread {
            progressHUDView?.setText(text)
                ?: run {
                    progressHUDView = ProgressHUDView(this)
                    progressHUDView?.setText(text)
                    rootViewGroup.addView(progressHUDView)
                    window.setFlags(
                        WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                        WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                    )
                }
        }
    }

    fun hideProgressHUD() {
        runOnUiThread {
            progressHUDView?.let {
                rootViewGroup.removeView(it)
                window.clearFlags(WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE)
                progressHUDView = null
            }
        }
    }

    fun showError(text: String) {
        runOnUiThread {
            errorHUDView?.setMessage(text)
                ?: run {
                    errorHUDView = AlertDialog.Builder(this)
                        .setTitle("Error")
                        .setMessage(text)
                        .setPositiveButton("Ok") { _, _ -> errorHUDView = null }
                        .setCancelable(false)
                        .show()
                }
        }
    }

    open fun showConnectionError(text: String?) {
        runOnUiThread {
            errorHUDView?.dismiss()

            errorHUDView = AlertDialog.Builder(this)
                .setTitle("Connection error")
                .setMessage(text)
                .setPositiveButton("Try again") { _, _ ->
                    model.reconnect()
                    errorHUDView = null
                }
                .setCancelable(false)
                .show()
        }
    }
}