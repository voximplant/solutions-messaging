package com.voximplant.demos.messaging.repository.local

import androidx.lifecycle.LiveData
import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy.REPLACE
import androidx.room.Query
import com.voximplant.demos.messaging.entity.Conversation

@Dao
interface ConversationDao {
    @Query("SELECT * FROM conversation")
    fun getAll(): LiveData<List<Conversation>>

    @Query("SELECT * FROM conversation WHERE uuid LIKE (:uuid)")
    fun loadByUUID(uuid: String): Conversation?

    @Insert(onConflict = REPLACE)
    fun insertAllConversations(conversations: List<Conversation>)

    @Insert(onConflict = REPLACE)
    fun insert(conversation: Conversation)

    @Delete
    fun delete(conversation: Conversation)

    @Query("DELETE FROM conversation WHERE uuid = :uuid")
    fun deleteByUUID(uuid: String)

    @Query("DELETE FROM conversation")
    fun deleteAll()

    @Query("UPDATE conversation SET lastUpdated = :lastUpdated, lastSequence = :lastSequence WHERE uuid LIKE :uuid")
    fun updateLastUpdated(lastUpdated: Long, lastSequence: Long, uuid: String)
}
