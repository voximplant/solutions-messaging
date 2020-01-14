package com.voximplant.demos.messaging.ui.createDirect

import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.Transformations
import androidx.lifecycle.viewModelScope
import com.voximplant.demos.messaging.entity.User
import com.voximplant.demos.messaging.utils.BaseViewModel
import kotlinx.coroutines.launch

class CreateDirectViewModel: BaseViewModel() {
    val users = Transformations.map(repository.users) { users ->
        val usersCopy = users.toMutableList()

        usersCopy.removeAll { it.imId == repository.me }
        usersCopy
    }

    val showActiveConversation = MutableLiveData<Unit>()

    fun onSelect(user: User) {
        viewModelScope.launch {
            if (repository.createDirectConversation(user)) {
                hideProgress.postValue(Unit)
                showActiveConversation.postValue(Unit)
            } else {
                hideProgress.postValue(Unit)
                postError("Could'nt create conversation")
            }
        }
    }
}