package com.voximplant.demos.messaging.ui.activeConversation

import androidx.lifecycle.LiveData
import androidx.lifecycle.Observer
import androidx.lifecycle.Transformations
import androidx.lifecycle.liveData
import androidx.lifecycle.viewModelScope
import androidx.paging.PagedList
import androidx.paging.toLiveData
import com.voximplant.demos.messaging.entity.Conversation
import com.voximplant.demos.messaging.entity.ConversationType
import com.voximplant.demos.messaging.entity.events.MessengerEvent
import com.voximplant.demos.messaging.entity.events.ServiceEventAction.TYPING
import com.voximplant.demos.messaging.repository.RepositoryDataStateNotifier
import com.voximplant.demos.messaging.repository.utils.image
import com.voximplant.demos.messaging.repository.utils.type
import com.voximplant.demos.messaging.utils.BaseViewModel
import com.voximplant.demos.messaging.utils.ifNull
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.*
import kotlin.concurrent.timerTask

class ActiveConversationViewModel : BaseViewModel(), RepositoryDataStateNotifier {

    private val activeConversation = repository.activeConversation

    private val dataSourceFactory = ActiveConversationDataSourceFactory(
        repository,
        activeConversation,
        viewModelScope.coroutineContext
    )

    private val config = PagedList.Config.Builder()
        .setInitialLoadSizeHint(100)
        .setPageSize(33)
        .setEnablePlaceholders(false)
        .build()

    val messages: LiveData<PagedList<MessengerEventModel>> = dataSourceFactory.toLiveData(config)

    val title = Transformations.switchMap(activeConversation) {
        liveData(viewModelScope.coroutineContext + Dispatchers.IO) {
            val conversation = it
                .ifNull {
                    emit(null)
                    return@liveData
                }

            if (conversation.isDirect) {
                val participantImId = conversation.participants
                    .first { it != repository.me }
                emit(repository.requestUser(participantImId)?.displayName)
            } else {
                emit(conversation.title)
            }
        }
    }

    val imageName = Transformations.switchMap(activeConversation) {
        liveData(viewModelScope.coroutineContext + Dispatchers.IO) {
            val conversation = it
                .ifNull {
                    emit(null)
                    return@liveData
                }

            if (conversation.isDirect) {
                val participantImId = conversation.participants
                    .first { it != repository.me }
                emit(repository.requestUser(participantImId)?.customData?.image)
            } else {
                emit(conversation.customData.image)
            }
        }
    }

    val myPermissions = Transformations.switchMap(activeConversation) {
        liveData(viewModelScope.coroutineContext + Dispatchers.IO) {
            val conversation = it
                .ifNull {
                    emit(null)
                    return@liveData
                }

            val participant = repository.requestParticipant(
                conversation.uuid,
                conversation.participants.first { it == repository.me }
            ).ifNull {
                emit(null)
                return@liveData
            }

            emit(participant.permissions)
        }
    }

    private val activeConversationObserver = Observer<Conversation?> {
        it?.let {
            repository.markAsRead(it.lastSequence, it)
        } ?: finish.postValue(Unit)
    }

    init {
        repository.setDataNotifier(this)

        activeConversation.observeForever(activeConversationObserver)
    }

    fun finish() {
        activeConversation.removeObserver(activeConversationObserver)
        repository.changeStoredActiveConversation(null)
        finish.postValue(Unit)
    }

    fun sendButtonClick(text: String?, sendingHandler: (Boolean) -> Unit) {
        viewModelScope.launch {
            val messageText = text
                ?.takeIf { it.isNotEmpty() }
                .ifNull {
                    sendingHandler(false)
                    return@launch
                }

            val conversation = activeConversation.value
                .ifNull {
                    sendingHandler(false)
                    return@launch
                }

            sendingHandler(repository.sendMessage(messageText, conversation))
        }
    }

    fun menuButtonPressed(completion: (Long?) -> Unit) {
        activeConversation.value
            ?.let { conversation ->
                if (conversation.customData.type == ConversationType.DIRECT.stringValue) {
                    val userImId = conversation.participants.first { it != repository.me }
                    completion(userImId)
                } else {
                    completion(null)
                }
            }
    }

    fun sendTyping() {
        activeConversation.value?.let {
            repository.sendTyping(it)
        }
    }

    fun requestMessageInfo(sequence: Long, infoHandler: (String?) -> Unit) {
        viewModelScope.launch {
            val conversation = activeConversation.value
                .ifNull {
                    infoHandler(null)
                    return@launch
                }

            val message = repository.findMessage(sequence, conversation.uuid)
                .ifNull {
                    infoHandler(null)
                    return@launch
                }

            infoHandler(message.text)
        }
    }

    fun editMessage(sequence: Long, newText: String?, editingHandler: (Boolean) -> Unit) {
        viewModelScope.launch {
            val text = newText
                .ifNull {
                    editingHandler(false)
                    return@launch
                }

            val conversation = activeConversation.value
                .ifNull {
                    editingHandler(false)
                    return@launch
                }

            editingHandler(repository.findAndEditMessage(sequence, text, conversation))
        }
    }

    fun removeMessage(sequence: Long, removingHandler: (Boolean) -> Unit) {
        viewModelScope.launch {
            val conversation = activeConversation.value
                .ifNull {
                    removingHandler(false)
                    return@launch
                }

            removingHandler(repository.findAndRemoveMessage(sequence, conversation))
        }
    }

    override fun onServiceEvent(event: MessengerEvent.ServiceEvent) {
        viewModelScope.launch {
            super.onServiceEvent(event)

            if (event.conversationUUID != activeConversation.value?.uuid) {
                return@launch
            }

            if (event.action == TYPING) {
                val user = repository.requestUser(event.initiatorImId)
                    .ifNull {
                        return@launch
                    }

                subtitle.postValue("${user.displayName} is typing...")

                Timer().schedule(
                    timerTask { subtitle.postValue(null) },
                    9000
                )
            }
        }
    }

    override fun dataUpdated() {
        dataSourceFactory.sourceLiveData.value?.invalidate()
    }
}