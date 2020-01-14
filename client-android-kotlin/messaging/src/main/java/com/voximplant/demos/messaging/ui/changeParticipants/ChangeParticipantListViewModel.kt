package com.voximplant.demos.messaging.ui.changeParticipants

import androidx.lifecycle.*
import com.voximplant.demos.messaging.entity.Participant
import com.voximplant.demos.messaging.entity.User
import com.voximplant.demos.messaging.ui.changeParticipants.ChangeParticipantListModuleType.*
import com.voximplant.demos.messaging.utils.BaseViewModel
import com.voximplant.demos.messaging.utils.ifNull
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class ChangeParticipantListViewModel: BaseViewModel() {
    private val activeConversation = repository.activeConversation
    private val users = repository.users

    var possibleToAddParticipants = MediatorLiveData<List<User>>()
    var possibleToRemoveParticipants = Transformations.switchMap(activeConversation) {
        val neededImIds: MutableList<Long> = mutableListOf()

        it?.participants?.forEach { participant ->
            if (participant != repository.me) {
                neededImIds.add(participant)
            }
        }

        liveData(viewModelScope.coroutineContext + Dispatchers.IO) {
            emit(repository.requestUsers(neededImIds))
        }
    }

    var possibleToAddAdmins = Transformations.switchMap(activeConversation) {
        liveData(viewModelScope.coroutineContext + Dispatchers.IO) {
            val conversation = it
                .ifNull {
                    emit(emptyList())
                    return@liveData
                }

            val allParticipants = repository.requestParticipants(conversation.uuid)
            if (allParticipants.isEmpty()) {
                emit(emptyList())
                return@liveData
            }

            val notAdmins: MutableList<Participant> = mutableListOf()
            allParticipants.forEach { participant ->
                if (!participant.isOwner) {
                    notAdmins.add(participant)
                }
            }
            if (notAdmins.isEmpty()) {
                emit(emptyList())
                return@liveData
            }

            emit(repository.requestUsers(notAdmins.map { it.userImId }))
        }
    }
    var possibleToRemoveAdmins = Transformations.switchMap(activeConversation) {
        liveData(viewModelScope.coroutineContext + Dispatchers.IO) {
            val conversation = it
                .ifNull {
                    emit(emptyList())
                    return@liveData
                }

            val allParticipants = repository.requestParticipants(conversation.uuid)
            if (allParticipants.isEmpty()) {
                emit(emptyList())
                return@liveData
            }

            val neededImIds: MutableList<Long> = mutableListOf()

            allParticipants.forEach { participant ->
                if (participant.userImId != repository.me && participant.isOwner) {
                    neededImIds.add(participant.userImId)
                }
            }

            emit(repository.requestUsers(neededImIds))
        }
    }

    val chosenUsers = MutableLiveData<MutableList<User>>()

    private val _exitScreen = MutableLiveData<Unit>()
    val exitScreen: LiveData<Unit>
        get() = _exitScreen

    override fun onCreate() {
        super.onCreate()

        chosenUsers.postValue(mutableListOf())

        possibleToAddParticipants
            .addSource(users) { users ->
                activeConversation.value?.let { conversation ->

                    val usersCopy = users.toMutableList()

                    conversation.participants.forEach { participant ->
                        usersCopy.removeAll { it.imId == participant }
                    }

                    possibleToAddParticipants.postValue(usersCopy)
                }
            }

        possibleToAddParticipants
            .addSource(activeConversation) { activeConversation ->
                val conversation = activeConversation
                    .ifNull { return@addSource }

                users.value?.let { users ->
                    val usersCopy = users.toMutableList()

                    conversation.participants.forEach { participant ->
                        usersCopy.removeAll { it.imId == participant }
                    }

                    possibleToAddParticipants.postValue(usersCopy)
                }
            }
    }

    fun onSelectUser(user: User) {
        chosenUsers.value?.let { chosenUsersValue ->
            if (chosenUsersValue.contains(user)) {
                chosenUsersValue.remove(user)
                chosenUsers.postValue(chosenUsersValue)
            } else {
                chosenUsersValue.add(user)
                chosenUsers.postValue(chosenUsersValue)
            }
        }
    }

    fun onSaveButtonPressed(type: ChangeParticipantListModuleType, savingHandler: (Boolean) -> Unit) {
        viewModelScope.launch {
            val conversation = activeConversation.value
                .ifNull {
                    savingHandler(false)
                    return@launch
                }

            val users = chosenUsers.value
                .ifNull {
                    savingHandler(false)
                    return@launch
                }

            when (type) {
                AddParticipants -> savingHandler(
                    repository.addUsersToConversation(users, conversation)
                )

                AddAdmins -> savingHandler(
                    repository.addAdmins(users, conversation)
                )

                RemoveAdmins -> savingHandler(
                    repository.removeAdmins(users, conversation)
                )

                RemoveParticipants -> savingHandler(
                    repository.removeUsersFromConversation(users, conversation)
                )
            }
        }
    }

}