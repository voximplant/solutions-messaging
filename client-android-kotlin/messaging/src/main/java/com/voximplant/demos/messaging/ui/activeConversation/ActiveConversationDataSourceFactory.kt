package com.voximplant.demos.messaging.ui.activeConversation

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.paging.DataSource
import com.voximplant.demos.messaging.entity.Conversation
import com.voximplant.demos.messaging.repository.Repository
import kotlin.coroutines.CoroutineContext

class ActiveConversationDataSourceFactory(
    val repository: Repository,
    val activeConversation: LiveData<Conversation?>,
    private val coroutineContext: CoroutineContext,
) : DataSource.Factory<Long, MessengerEventModel>() {

    val sourceLiveData = MutableLiveData<ActiveConversationDataSource>()
    private lateinit var latestSource: ActiveConversationDataSource

    override fun create(): DataSource<Long, MessengerEventModel> {
        latestSource =
            ActiveConversationDataSource(repository, activeConversation.value, coroutineContext)
        sourceLiveData.postValue(latestSource)
        return latestSource
    }
}