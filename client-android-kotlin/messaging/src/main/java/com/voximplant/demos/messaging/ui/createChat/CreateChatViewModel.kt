package com.voximplant.demos.messaging.ui.createChat

import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.Transformations
import androidx.lifecycle.viewModelScope
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.entity.ConversationType
import com.voximplant.demos.messaging.entity.ConversationType.CHANNEL
import com.voximplant.demos.messaging.entity.ConversationType.CHAT
import com.voximplant.demos.messaging.entity.User
import com.voximplant.demos.messaging.utils.BaseViewModel
import kotlinx.coroutines.launch

class CreateChatViewModel : BaseViewModel() {
    val users = Transformations.map(repository.users) { it }

    private val chosenUsers: MutableList<User> = mutableListOf()

    val showActiveConversation = MutableLiveData<Unit>()

    fun createConversation(
        type: ConversationType,
        title: String,
        description: String?,
        pictureName: String?,
        isPublic: Boolean,
        isUber: Boolean,
    ) {
        viewModelScope.launch {
            showProgress.postValue(R.string.progress_creating)

            if (chosenUsers.isEmpty()) {
                postError("Can't create ${type.stringValue} without users!")
                hideProgress.postValue(Unit)
                return@launch
            }

            when (type) {
                CHAT ->
                    if (repository.createGroupConversation(
                            title,
                            chosenUsers,
                            description,
                            pictureName,
                            isPublic,
                            isUber
                        )
                    ) {
                        hideProgress.postValue(Unit)
                        showActiveConversation.postValue(Unit)
                        finish.postValue(Unit)
                    } else {
                        hideProgress.postValue(Unit)
                        postError("Could'nt create conversation")
                    }

                CHANNEL ->
                    if (repository.createChannel(title, chosenUsers, description, pictureName)
                    ) {
                        hideProgress.postValue(Unit)
                        showActiveConversation.postValue(Unit)
                        finish.postValue(Unit)
                    } else {
                        hideProgress.postValue(Unit)
                        postError("Could'nt create conversation")
                    }

                else -> return@launch
            }
        }
    }

    fun onSelectUser(user: User) {
        if (chosenUsers.contains(user)) {
            chosenUsers.remove(user)
        } else {
            chosenUsers.add(user)
        }
    }
}