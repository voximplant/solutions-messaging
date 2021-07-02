package com.voximplant.demos.messaging.entity

import androidx.room.ColumnInfo
import com.voximplant.demos.messaging.utils.payload.Payload

data class Message(
    val uuid: String,
    val text: String,
    val payload: Payload?,
    val conversation: String,
    @ColumnInfo(name = "message_sequence") val sequence: Long
)