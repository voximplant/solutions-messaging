package com.voximplant.demos.messaging.ui.editConversationInfo

import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.Transformations
import androidx.lifecycle.liveData
import androidx.lifecycle.viewModelScope
import com.voximplant.demos.messaging.entity.ConversationType
import com.voximplant.demos.messaging.repository.utils.chatDescription
import com.voximplant.demos.messaging.repository.utils.image
import com.voximplant.demos.messaging.repository.utils.status
import com.voximplant.demos.messaging.repository.utils.type
import com.voximplant.demos.messaging.utils.BaseViewModel
import com.voximplant.demos.messaging.utils.ifNull
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class EditConversationInfoViewModel : BaseViewModel() {
    private val activeConversation = repository.activeConversation

    val conversationType = Transformations.map(activeConversation) {
        it?.let {
            it.customData.type?.let { type ->
                ConversationType.from(type)
            }
        }
    }
    val conversationTitle = Transformations.switchMap(activeConversation) {
        liveData(viewModelScope.coroutineContext + Dispatchers.IO) {
            val conversation = it
                .ifNull {
                    emit("")
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
    val conversationDescription = Transformations.map(activeConversation) {
        it?.let {
            if (it.isDirect) {
                it.customData.status
            } else {
                it.customData.chatDescription
            }
        }
    }
    val conversationImageName = Transformations.map(activeConversation) {
        it?.customData?.image
    }

    val conversationIsPublic = Transformations.map(activeConversation) {
        it?.isPublic
    }

    val exitScreen = MutableLiveData<Unit>()

    fun onSaveButtonClicked(
        title: String,
        description: String?,
        imageName: String?,
        public: Boolean
    ) {
        viewModelScope.launch {
            activeConversation.value?.let { activeConversation ->
                if (!(activeConversation.title == title
                            && activeConversation.customData.chatDescription == description
                            && activeConversation.customData.image == imageName
                            && activeConversation.isPublic == public)
                ) {
                    if (repository.updateConversation(
                            activeConversation,
                            title,
                            description,
                            imageName,
                            public,
                        )
                    ) {
                        hideProgress.postValue(Unit)
                        finish.postValue(Unit)
                    } else {
                        hideProgress.postValue(Unit)
                        repository.activeConversation.postValue(repository.activeConversation.value)
                        postError("Could'nt update conversation")
                    }
                } else {
                    hideProgress.postValue(Unit)
                }
            }
        }
    }

    fun onLeaveButtonClicked() {
        viewModelScope.launch {
            val conversation = activeConversation.value
                .ifNull { return@launch }

            if (repository.leaveConversation(conversation.uuid)) {
                hideProgress.postValue(Unit)
                exitScreen.postValue(Unit)
            } else {
                hideProgress.postValue(Unit)
                postError("Could'nt leave conversation")
            }
        }
    }
}