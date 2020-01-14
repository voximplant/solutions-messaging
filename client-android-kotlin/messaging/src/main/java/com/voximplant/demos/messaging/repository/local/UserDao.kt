package com.voximplant.demos.messaging.repository.local

import androidx.lifecycle.LiveData
import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.voximplant.demos.messaging.entity.User

@Dao
interface UserDao {
    @Query("SELECT * FROM user")
    fun getAll(): LiveData<List<User>>

    @Query("SELECT * FROM user WHERE imId IN (:imIds)")
    suspend fun loadAllByImIds(imIds: List<Long>): List<User>

    @Query("SELECT * FROM user WHERE imId LIKE (:imId)")
    suspend fun loadUserByImId(imId: Long): User?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAllUsers(users: List<User>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertUser(user: User)

    @Query("DELETE FROM user")
    fun deleteAll()
}