package com.voximplant.demos.messaging.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import com.voximplant.demos.messaging.utils.permissions.Permissions

@Entity(primaryKeys = ["conversation_uuid", "userImId"])
data class Participant(
    @ColumnInfo(name = "conversation_uuid") val conversationUUID: String,
    var isOwner: Boolean,
    var userImId: Long,
    var permissions: Permissions,
    var lastReadSequence: Long
)