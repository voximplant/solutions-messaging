package com.voximplant.demos.messaging.entity

import androidx.room.ColumnInfo

data class Message(
    val uuid: String,
    val text: String,
    val conversation: String,
    @ColumnInfo(name = "message_sequence") val sequence: Long
)