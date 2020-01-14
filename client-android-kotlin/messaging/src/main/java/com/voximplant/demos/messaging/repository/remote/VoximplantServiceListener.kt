package com.voximplant.demos.messaging.repository.remote

import android.util.Log
import com.voximplant.demos.messaging.utils.APP_TAG
import com.voximplant.sdk.messaging.IConversationEvent
import com.voximplant.sdk.messaging.IConversationServiceEvent
import com.voximplant.sdk.messaging.IMessageEvent
import com.voximplant.sdk.messaging.IUserEvent

interface VoximplantServiceListener {
    fun onConversationEvent(voxEvent: IConversationEvent) {
        Log.e(APP_TAG, "onIConversationEvent")
    }
    fun onMessageEvent(voxEvent: IMessageEvent) {
        Log.e(APP_TAG, "onIMessageEvent")
    }
    fun onServiceEvent(voxEvent: IConversationServiceEvent) {
        Log.e(APP_TAG, "on ${voxEvent.messengerAction}, seq: ${voxEvent.sequence}, user: ${voxEvent.imUserId}")
    }
    fun onUserEvent(voxEvent: IUserEvent) {
        Log.e(APP_TAG, "onIUserEvent")
    }
}