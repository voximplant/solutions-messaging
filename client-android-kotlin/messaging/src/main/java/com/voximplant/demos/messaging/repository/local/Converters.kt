package com.voximplant.demos.messaging.repository.local

import androidx.room.TypeConverter
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.voximplant.demos.messaging.entity.events.ConversationEventAction
import com.voximplant.demos.messaging.entity.events.MessageEventAction
import com.voximplant.demos.messaging.repository.utils.CustomData
import com.voximplant.demos.messaging.utils.payload.Payload
import com.voximplant.demos.messaging.utils.permissions.Permissions

class Converters {
    @TypeConverter
    fun stringToList(value: String?): List<Long> {
        if (value == null) {
            return listOf()
        }

        val listType = object : TypeToken<List<Long>>() {}.type

        return Gson().fromJson(value, listType)
    }

    @TypeConverter
    fun listToString(value: List<Long>): String {
        return Gson().toJson(value)
    }

    @TypeConverter
    fun stringToCustomData(value: String?): CustomData {
        value?.let {
            val type = object: TypeToken<CustomData>() {}.type
            return Gson().fromJson(value, type)
        }
            ?: return mutableMapOf()
    }

    @TypeConverter
    fun customDataToString(value: CustomData): String {
        return Gson().toJson(value)
    }


    @TypeConverter
    fun fromMessageEventAction(value: MessageEventAction): Int {
        return when (value) {
            MessageEventAction.SEND -> 0
            MessageEventAction.EDIT -> 1
            MessageEventAction.REMOVE -> 2
        }
    }

    @TypeConverter
    fun toMessageEventAction(value: Int): MessageEventAction {
        return when (value) {
            0 -> MessageEventAction.SEND
            1 -> MessageEventAction.EDIT
            2 -> MessageEventAction.REMOVE
            else -> throw IllegalArgumentException("$value is Unknown")
        }
    }

    @TypeConverter
    fun fromConversationEventAction(value: ConversationEventAction): Int {
        return when (value) {
            ConversationEventAction.ADD_PARTICIPANTS -> 0
            ConversationEventAction.EDIT_PARTICIPANTS -> 1
            ConversationEventAction.REMOVE_PARTICIPANTS -> 2
            ConversationEventAction.EDIT_CONVERSATION -> 3
            ConversationEventAction.JOIN_CONVERSATION -> 4
            ConversationEventAction.LEAVE_CONVERSATION -> 5
            ConversationEventAction.CREATE_CONVERSATION -> 6
            ConversationEventAction.REMOVE_CONVERSATION -> 7
        }
    }

    @TypeConverter
    fun toConversationEventAction(value: Int): ConversationEventAction {
        return when (value) {
            0 -> ConversationEventAction.ADD_PARTICIPANTS
            1 -> ConversationEventAction.EDIT_PARTICIPANTS
            2 -> ConversationEventAction.REMOVE_PARTICIPANTS
            3 -> ConversationEventAction.EDIT_CONVERSATION
            4 -> ConversationEventAction.JOIN_CONVERSATION
            5 -> ConversationEventAction.LEAVE_CONVERSATION
            6 -> ConversationEventAction.CREATE_CONVERSATION
            7 -> ConversationEventAction.REMOVE_CONVERSATION
            else -> throw throw IllegalArgumentException("$value is Unknown")
        }
    }

    @TypeConverter
    fun fromPermissions(value: Permissions): String {
        return Gson().toJson(value)
    }

    @TypeConverter
    fun toPermissions(value: String): Permissions {
        val listType = object : TypeToken<Permissions>() {}.type

        return Gson().fromJson(value, listType)
    }

    @TypeConverter
    fun fromPayloadToJSON(payload: Payload?): String = Gson().toJson(payload)

    @TypeConverter
    fun fromJSONToPayload(json: String?): Payload? {
        val type = object : TypeToken<Payload>() {}.type
        return Gson().fromJson(json, type)
    }
}

