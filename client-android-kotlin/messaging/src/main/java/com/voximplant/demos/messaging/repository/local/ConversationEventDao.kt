package com.voximplant.demos.messaging.repository.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy.REPLACE
import androidx.room.Query
import com.voximplant.demos.messaging.entity.events.MessengerEvent.ConversationEvent

@Dao
interface ConversationEventDao {
    @Query("SELECT * FROM conversationevent WHERE conversation = :conversationUUID ORDER BY sequence")
    fun getAll(conversationUUID: String): List<ConversationEvent>

    @Query("SELECT * FROM conversationevent WHERE conversation = :conversationUUID AND sequence = :sequence")
    suspend fun get(conversationUUID: String, sequence: Long): ConversationEvent?

    @Insert(onConflict = REPLACE)
    fun insertAll(event: List<ConversationEvent>)

    @Insert(onConflict = REPLACE)
    fun insert(event: ConversationEvent)

    @Query("DELETE FROM conversationevent")
    fun deleteAll()

    @Query("DELETE FROM conversationevent WHERE conversation = :uuid")
    fun deleteAllWithUUID(uuid: String)
}