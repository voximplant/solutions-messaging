package com.voximplant.demos.messaging.repository.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.voximplant.demos.messaging.entity.Conversation
import com.voximplant.demos.messaging.entity.Participant
import com.voximplant.demos.messaging.entity.User
import com.voximplant.demos.messaging.entity.events.MessengerEvent.ConversationEvent
import com.voximplant.demos.messaging.entity.events.MessengerEvent.MessageEvent

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