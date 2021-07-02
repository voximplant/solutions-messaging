package com.voximplant.demos.messaging.ui.userSearch

import androidx.lifecycle.*
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.entity.User
import com.voximplant.demos.messaging.utils.BaseViewModel
import com.voximplant.demos.messaging.utils.Shared.accName
import com.voximplant.demos.messaging.utils.Shared.appName
import kotlinx.coroutines.launch

class UserSearchViewModel : BaseViewModel() {
    private val _filteredUsers = MediatorLiveData<List<User>?>()
    val filteredUsers: LiveData<List<User>?> = _filteredUsers
    val usersList = MediatorLiveData<List<User>?>()
    private val _filterString = MutableLiveData<String>()
    val filterString: LiveData<String> = _filterString

    val useMultipleSelection = MutableLiveData(false)
    val useGlobalSearch = MutableLiveData(true)

    private val _selectedItem = MutableLiveData<User>()
    val selectedItem: LiveData<User> get() = _selectedItem

    init {
        _filteredUsers.addSource(usersList) { filter() }
        _filteredUsers.addSource(_filterString) { filter() }
    }

    private fun filter() {
        _filteredUsers.value = usersList.value?.filter { user ->
            val search: String = _filterString.value.toString()

            val isMe: Boolean = user.imId == repository.me
            val isMatchesSearch: Boolean =
                user.displayName.contains(search, true) ||
                        user.name.substringBefore("@").contains(search, true)
            !isMe && isMatchesSearch
        }
    }

    fun searchUser(name: String = "") {
        _filterString.value = name
    }

    fun globalSearchUser(username: String = "") {
        val postfix = "@$appName.$accName"
        viewModelScope.launch {
            if (repository.users.value?.any { user -> user.name == username.plus(postfix) } == true) {
                postToast(R.string.user_already_exists)
            } else {
                showProgress.postValue(R.string.progress_search_user)
                val result = repository.requestUser(username.plus(postfix))
                if (result == null) {
                    postToast(R.string.user_not_found)
                }
                hideProgress.postValue(Unit)
            }
        }
    }

    fun onSelect(user: User) {
        _selectedItem.value = user
    }
}