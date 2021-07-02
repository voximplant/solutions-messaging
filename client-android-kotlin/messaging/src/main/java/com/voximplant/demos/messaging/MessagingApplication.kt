package com.voximplant.demos.messaging

import android.app.Application
import androidx.appcompat.app.AppCompatDelegate
import com.voximplant.demos.messaging.manager.VoxClientManager
import com.voximplant.demos.messaging.repository.Repository
import com.voximplant.demos.messaging.utils.Shared
import com.voximplant.sdk.Voximplant
import com.voximplant.sdk.client.ClientConfig
import java.util.concurrent.Executors

class MessagingApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        val config = ClientConfig()
        config.packageName = packageName

        val client = Voximplant.getClientInstance(
            Executors.newSingleThreadExecutor(),
            applicationContext,
            config,
        )
        val clientManager = VoxClientManager(client, applicationContext)
        val repository = Repository(applicationContext)

        clientManager.addListener(repository)

        Shared.clientManager = clientManager
        Shared.repository = repository

        AppCompatDelegate.setCompatVectorFromResourcesEnabled(true)
    }
}