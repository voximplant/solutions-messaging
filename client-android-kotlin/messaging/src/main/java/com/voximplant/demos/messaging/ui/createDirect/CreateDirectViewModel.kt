package com.voximplant.demos.messaging.ui.createDirect

import androidx.lifecycle.*
import com.voximplant.demos.messaging.entity.User
import com.voximplant.demos.messaging.utils.BaseViewModel
import kotlinx.coroutines.launch

class CreateDirectViewModel : BaseViewModel() {

    val users = Transformations.map(repository.users) { it }

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