package com.voximplant.demos.messaging.manager

import android.util.Log
import com.voximplant.demos.messaging.utils.APP_TAG
import com.voximplant.sdk.client.LoginError

interface VoxClientManagerListener {
    fun onConnectionFailed(error: String) {
        Log.e(APP_TAG, "Connection failed")
    }

    fun onConnectionClosed() {
        Log.i(APP_TAG, "Connection closed")
    }

    fun onLoginFailed(error: LoginError) {
        Log.e(APP_TAG, "Login failed $error")
    }

    fun onAlreadyLoggedIn(displayName: String) {
        Log.i(APP_TAG, "onAlreadyLoggedIn $displayName")
    }

    fun onLoginSuccess(displayName: String) {
        Log.i(APP_TAG, "Login success $displayName")
    }

    fun onLogout() {
        Log.i(APP_TAG, "Logout completed")
    }
}