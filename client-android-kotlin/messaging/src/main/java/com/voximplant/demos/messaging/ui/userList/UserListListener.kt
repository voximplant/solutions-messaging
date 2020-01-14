package com.voximplant.demos.messaging.ui.userList

import com.voximplant.demos.messaging.entity.User

interface UserListListener {
    fun onSelect(user: User)
}