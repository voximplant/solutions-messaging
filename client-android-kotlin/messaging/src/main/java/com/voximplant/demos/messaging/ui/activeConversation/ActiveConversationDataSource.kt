package com.voximplant.demos.messaging.ui.activeConversation

import androidx.paging.ItemKeyedDataSource
import com.voximplant.demos.messaging.entity.Conversation
import com.voximplant.demos.messaging.repository.Repository
import com.voximplant.demos.messaging.utils.ifNull
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlin.coroutines.CoroutineContext

class ActiveConversationDataSource(
    val repository: Repository,
    val conversation: Conversation?,
    override val coroutineContext: CoroutineContext
) : ItemKeyedDataSource<Long, MessengerEventModel>(), CoroutineScope {

    override fun getKey(item: MessengerEventModel) = item.sequence - 1

    override fun loadInitial(
        params: LoadInitialParams<Long>,
        callback: LoadInitialCallback<MessengerEventModel>
    ) {
        launch {
            val conversation = conversation
                .ifNull { return@launch }

            val eventsWithData = repository.requestMessengerEvents(
                conversation,
                params.requestedLoadSize,
                conversation.lastSequence
            )

            callback
                .onResult(eventsWithData.first
                    .map {
                        MessengerEventModel.buildWith(
                            it.event,
                            it.initiatorName,
                            it.isMy,
                            eventsWithData.second >= it.event.sequence
                        )
                    }
                )
        }
    }

    override fun loadBefore(
        params: LoadParams<Long>,
        callback: LoadCallback<MessengerEventModel>
    ) {
        launch {
            if (params.key.toInt() == 0) {
                return@launch
            }

            val conversation = conversation
                .ifNull { return@launch }

            if (params.key == conversation.lastSequence) {
                callback.onResult(emptyList())
            } else {
                val eventsWithData = repository.requestMessengerEvents(
                    conversation,
                    params.requestedLoadSize,
                    params.key
                )

                callback
                    .onResult(eventsWithData.first
                        .map {
                            MessengerEventModel.buildWith(
                                it.event,
                                it.initiatorName,
                                it.isMy,
                                eventsWithData.second >= it.event.sequence
                            )
                        }
                    )
            }
        }
    }

    override fun loadAfter(params: LoadParams<Long>, callback: LoadCallback<MessengerEventModel>) { } // not used
}
