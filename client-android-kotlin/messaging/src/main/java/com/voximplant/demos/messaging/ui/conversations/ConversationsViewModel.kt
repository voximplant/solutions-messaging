package com.voximplant.demos.messaging.ui.conversations

import androidx.lifecycle.Transformations
import androidx.lifecycle.liveData
import androidx.lifecycle.viewModelScope
import com.voximplant.demos.messaging.utils.BaseViewModel
import com.voximplant.demos.messaging.utils.ifNull
import kotlinx.coroutines.Dispatchers

class ConversationsViewModel : BaseViewModel() {
    private val conversations = repository.conversations
    val conversationModels = Transformations.switchMap(conversations) {
        liveData(viewModelScope.coroutineContext + Dispatchers.IO) {

            var neededUserImIds: MutableList<Long> = mutableListOf()

            it.forEach { conversation ->
                if (conversation.isDirect) {
                    val neededUserImId = try {
                        conversation.participants.first { it != repository.me }
                    } catch (error: Error) {
                        emit(emptyList())
                        return@liveData
                    }
                    neededUserImIds.add(neededUserImId)
                }
            }

            neededUserImIds = neededUserImIds.distinct().toMutableList()

            val list = it
                .takeIf { it.isNotEmpty() }
                .ifNull {
                    emit(emptyList())
                    return@liveData
                }

            if (neededUserImIds.size > 0) {

                val users = repository.requestUsers(neededUserImIds)
                    .takeIf { it.isNotEmpty() }
                    .ifNull {
                        emit(emptyList())
                        return@liveData
                    }

                val modelList: MutableList<ConversationModel> = mutableListOf()

                list
                    .takeIf { it.isNotEmpty() }
                    .ifNull {
                        emit(emptyList())
                        return@liveData
                    }
                    .forEach { conversation ->
                    if (conversation.isDirect) {
                        val neededUserImId = conversation.participants
                            .firstOrNull { it != repository.me }
                            .ifNull {
                                emit(emptyList())
                                return@liveData
                            }

                        val user = users
                            .firstOrNull { it.imId == neededUserImId }
                            .ifNull {
                                emit(emptyList())
                                return@liveData
                            }
                        modelList.add(ConversationModel.buildDirect(conversation, user))
                    } else {
                        modelList.add(ConversationModel.buildGroup(conversation))
                    }
                }

                emit(
                    modelList
                        .sortedBy { it.lastUpdated }
                        .reversed()
                )
            } else {
                emit(
                    list
                        .map { ConversationModel.buildGroup(it) }
                        .sortedBy { it.lastUpdated }
                        .reversed()
                )
            }
        }
    }

    override fun onCreate() {
        super.onCreate()

        clientManager.loginWithToken()
    }

    fun onSelectConversation(model: ConversationModel) {
        repository.changeStoredActiveConversation(model.uuid)
    }

    fun onSettingsButtonPressed(completion: (Long) -> Unit) {
        repository.me?.let { me ->
            completion(me)
        }
    }
}