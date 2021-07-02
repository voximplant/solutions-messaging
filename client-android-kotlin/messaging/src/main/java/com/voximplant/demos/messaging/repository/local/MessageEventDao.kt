package com.voximplant.demos.messaging.repository.local

import androidx.room.*
import androidx.room.OnConflictStrategy.*
import com.voximplant.demos.messaging.entity.events.MessengerEvent.MessageEvent

@Dao
interface MessageEventDao {
    @Query("SELECT * FROM messageevent WHERE conversation = :conversationUUID ORDER BY sequence")
    fun getAll(conversationUUID: String): List<MessageEvent>

    @Query("SELECT * FROM messageevent WHERE conversation = :conversationUUID AND sequence = :sequence")
    suspend fun get(conversationUUID: String, sequence: Long): MessageEvent?

    @Insert(onConflict = REPLACE)
    fun insertAll(events: List<MessageEvent>)

    @Insert(onConflict = REPLACE)
    fun insert(event: MessageEvent)

    @Query("DELETE FROM messageevent")
    fun deleteAll()
}