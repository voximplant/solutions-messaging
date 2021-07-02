package com.voximplant.demos.messaging.utils

import android.annotation.SuppressLint
import com.voximplant.demos.messaging.manager.VoxClientManager
import com.voximplant.demos.messaging.repository.Repository

object Shared {
    @SuppressLint("StaticFieldLeak")
    lateinit var clientManager: VoxClientManager
    @SuppressLint("StaticFieldLeak")
    lateinit var repository: Repository

    var appName: String? = null
    var accName: String? = null
}