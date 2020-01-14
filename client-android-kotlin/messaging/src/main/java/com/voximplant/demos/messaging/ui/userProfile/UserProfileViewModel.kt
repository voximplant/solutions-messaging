package com.voximplant.demos.messaging.ui.userProfile

import androidx.lifecycle.Transformations
import androidx.lifecycle.viewModelScope
import com.voximplant.demos.messaging.utils.BaseViewModel
import kotlinx.coroutines.launch

class UserProfileViewModel : BaseViewModel() {
    private val users = repository.users

    var displayingUserImId: Long = 0

    val isMe : Boolean
        get() = displayingUserImId == repository.me

    val user = Transformations.map(users) { users ->
        if (displayingUserImId == 0.toLong()) {
            return@map null
        }
        users.firstOrNull { it.imId == displayingUserImId }
    }

    fun onSavePressed(status: String?, imageName: String?, savingHandler: (Boolean) -> Unit) {
        viewModelScope.launch {
            savingHandler(repository.editUser(status, imageName))
        }
    }

    fun onLogoutPressed() {
        clientManager.logout { loggedOut ->
            if (loggedOut) {
                hideProgress.postValue(Unit)
                showLogin.postValue(Unit)
            } else {
                postError("Could'nt perform logout")
            }
        }
    }
}