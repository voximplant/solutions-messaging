package com.voximplant.demos.messaging.repository.local

import androidx.lifecycle.LiveData
import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.voximplant.demos.messaging.entity.Participant

@Dao
interface ParticipantDao {
    @Query("SELECT * FROM participant")
    fun getAll(): LiveData<List<Participant>>

    @Query("SELECT * FROM participant WHERE userImId LIKE (:imId) AND conversation_uuid LIKE (:uuid)")
    suspend fun getByImId(imId: Long, uuid: String): Participant?

    @Query("SELECT * FROM participant WHERE userImId IN (:imIds) AND conversation_uuid LIKE (:uuid)")
    fun getAllByImId(imIds: List<Long>, uuid: String): List<Participant>

    @Query("SELECT * FROM participant WHERE conversation_uuid LIKE (:uuid)")
    suspend fun getAllByConversation(uuid: String): List<Participant>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertAll(participants: List<Participant>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(participant: Participant)

    @Query("DELETE FROM participant")
    fun deleteAll()

    @Query("DELETE FROM participant WHERE conversation_uuid LIKE (:UUID)")
    fun deleteAllWithUUID(UUID: String)

    @Query("DELETE FROM participant WHERE userImId IN (:imIds) AND conversation_uuid LIKE (:uuid)")
    fun deleteAllWithImIds(imIds: List<Long>, uuid: String)

    @Query("UPDATE participant SET lastReadSequence = :lastRead WHERE userImId LIKE :imId AND conversation_uuid LIKE :conversationUUID")
    fun updateLastRead(lastRead: Long, imId: Long, conversationUUID: String)
}