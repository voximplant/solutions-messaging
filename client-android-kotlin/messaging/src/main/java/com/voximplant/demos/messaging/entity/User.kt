package com.voximplant.demos.messaging.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.voximplant.demos.messaging.repository.utils.CustomData

@Entity
data class User(
    @PrimaryKey val imId: Long,
    var name: String,
    var displayName: String,
    var customData: CustomData
)