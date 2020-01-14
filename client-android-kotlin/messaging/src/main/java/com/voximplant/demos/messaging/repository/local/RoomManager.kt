package com.voximplant.demos.messaging.repository.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverter
import androidx.room.TypeConverters
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.voximplant.demos.messaging.entity.Conversation
import com.voximplant.demos.messaging.entity.Participant
import com.voximplant.demos.messaging.entity.User
import com.voximplant.demos.messaging.entity.events.ConversationEventAction
import com.voximplant.demos.messaging.entity.events.ConversationEventAction.*
import com.voximplant.demos.messaging.entity.events.MessageEventAction
import com.voximplant.demos.messaging.entity.events.MessengerEvent.ConversationEvent
import com.voximplant.demos.messaging.entity.events.MessengerEvent.MessageEvent
import com.voximplant.demos.messaging.repository.utils.CustomData
import com.voximplant.demos.messaging.utils.permissions.Permissions

@Database(
    entities = [User::class,
        MessageEvent::class,
        ConversationEvent::class,
        Conversation::class,
        Participant::class],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
    abstract fun messageEventDao(): MessageEventDao
    abstract fun conversationEventDao(): ConversationEventDao
    abstract fun conversationDao(): ConversationDao
    abstract fun participantDao(): ParticipantDao
}

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
            ADD_PARTICIPANTS -> 0
            EDIT_PARTICIPANTS -> 1
            REMOVE_PARTICIPANTS -> 2
            EDIT_CONVERSATION -> 3
            JOIN_CONVERSATION -> 4
            LEAVE_CONVERSATION -> 5
            CREATE_CONVERSATION -> 6
            REMOVE_CONVERSATION -> 7
        }
    }

    @TypeConverter
    fun toConversationEventAction(value: Int): ConversationEventAction {
        return when (value) {
            0 -> ADD_PARTICIPANTS
            1 -> EDIT_PARTICIPANTS
            2 -> REMOVE_PARTICIPANTS
            3 -> EDIT_CONVERSATION
            4 -> JOIN_CONVERSATION
            5 -> LEAVE_CONVERSATION
            6 -> CREATE_CONVERSATION
            7 -> REMOVE_CONVERSATION
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

}

