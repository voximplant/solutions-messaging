package com.voximplant.demos.messaging.entity

import com.voximplant.demos.messaging.utils.permissions.*

enum class ConversationType(val stringValue: String) {
    DIRECT("direct"),
    CHAT("chat"),
    CHANNEL("channel");

    val defaultPermissions
        get() = defaultPermissions(this)

    companion object {
        fun from(search: String)
                = requireNotNull(values().find { it.stringValue == search }) { "No TaskAction with value $search" }
    }
}
