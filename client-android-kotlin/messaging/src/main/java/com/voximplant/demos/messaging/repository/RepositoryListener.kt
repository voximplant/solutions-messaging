package com.voximplant.demos.messaging.repository

import android.util.Log
import com.voximplant.demos.messaging.entity.events.MessengerEvent.ServiceEvent
import com.voximplant.demos.messaging.utils.APP_TAG

interface RepositoryListener {
    fun onServiceEvent(event: ServiceEvent) {
        Log.e(APP_TAG, "onServiceEvent")
    }
    fun failedToConnectToBackend() {
        Log.e(APP_TAG, "failedToConnectToBackend")
    }
}