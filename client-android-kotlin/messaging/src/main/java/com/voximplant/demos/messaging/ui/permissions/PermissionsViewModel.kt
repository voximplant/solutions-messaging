package com.voximplant.demos.messaging.ui.permissions

import androidx.lifecycle.LiveData
import androidx.lifecycle.Transformations
import androidx.lifecycle.viewModelScope
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.repository.utils.permissions
import com.voximplant.demos.messaging.utils.BaseViewModel
import com.voximplant.demos.messaging.utils.ifNull
import com.voximplant.demos.messaging.utils.permissions.*
import kotlinx.coroutines.launch

class PermissionsViewModel : BaseViewModel() {
    private val activeConversation = repository.activeConversation

    val conversationPermissions: LiveData<Permissions> = Transformations.map(activeConversation) {
        it?.customData?.permissions
    }

    fun onSaveButtonPressed(
        canWrite: Boolean,
        canEdit: Boolean,
        canEditAll: Boolean,
        canRemove: Boolean,
        canRemoveAll: Boolean,
        canManage: Boolean
    ) {
        viewModelScope.launch {
            val conversation = activeConversation.value
                .ifNull { return@launch }

            val permissions: Permissions = mutableMapOf()
            permissions.canWrite = canWrite
            permissions.canEditMessages = canEdit
            permissions.canEditAllMessages = canEditAll
            permissions.canRemoveMessages = canRemove
            permissions.canRemoveAllMessages = canRemoveAll
            permissions.canManageParticipants = canManage

            if (permissions == conversation.customData.permissions) {
                return@launch
            }

            showProgress.postValue(R.string.progress_updating)

            if (repository.updateConversation(conversation, permissions)) {
                hideProgress.postValue(Unit)
            } else {
                hideProgress.postValue(Unit)
                repository.activeConversation.postValue(repository.activeConversation.value)
                postError("Could'nt update permissions")
            }
        }
    }

}