package com.voximplant.demos.messaging.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.voximplant.demos.messaging.repository.utils.CustomData

@Entity
data class Conversation(
    @PrimaryKey val uuid: String,
    var title: String,
    var participants: MutableList<Long>,
    var lastUpdated: Long,
    var lastSequence: Long,
    val isDirect: Boolean,
    var isPublic: Boolean,
    val isUber: Boolean,
    var customData: CustomData,
)