package com.voximplant.demos.messaging.utils.permissions

import com.voximplant.demos.messaging.entity.ConversationType
import com.voximplant.demos.messaging.entity.ConversationType.*

typealias Permissions = MutableMap<String, Boolean>

var Permissions.canWrite: Boolean
    get() = this[WRITE]!!
    set(value) = this.set(WRITE, value)

var Permissions.canEditMessages: Boolean
    get() = this[EDIT]!!
    set(value) = this.set(EDIT, value)

var Permissions.canEditAllMessages: Boolean
    get() = this[EDITALL]!!
    set(value) = this.set(EDITALL, value)

var Permissions.canRemoveMessages: Boolean
    get() = this[REMOVE]!!
    set(value) = this.set(REMOVE, value)

var Permissions.canRemoveAllMessages: Boolean
    get() = this[REMOVEALL]!!
    set(value) = this.set(REMOVEALL, value)

var Permissions.canManageParticipants: Boolean
    get() = this[MANAGE]!!
    set(value) = this.set(MANAGE, value)


fun defaultPermissions(type: ConversationType) : Permissions {
    return when (type) {
        DIRECT -> defaultDirectPermissions()
        CHAT    -> defaultChatPermissions()
        CHANNEL -> defaultChannelPermissions()
    }
}

fun defaultAdminPermissions() : Permissions {
    val permissions: Permissions = mutableMapOf()
    permissions.canWrite              = true
    permissions.canEditMessages       = true
    permissions.canEditAllMessages    = true
    permissions.canRemoveMessages     = true
    permissions.canRemoveAllMessages  = true
    permissions.canManageParticipants = true
    return permissions
}

private fun defaultDirectPermissions() : Permissions {
    val permissions: Permissions = mutableMapOf()
    permissions.canWrite              = true
    permissions.canEditMessages       = true
    permissions.canEditAllMessages    = false
    permissions.canRemoveMessages     = true
    permissions.canRemoveAllMessages  = false
    permissions.canManageParticipants = false
    return permissions
}

private fun defaultChatPermissions() : Permissions {
    val permissions: Permissions = mutableMapOf()
    permissions.canWrite              = true
    permissions.canEditMessages       = true
    permissions.canEditAllMessages    = false
    permissions.canRemoveMessages     = true
    permissions.canRemoveAllMessages  = false
    permissions.canManageParticipants = true
    return permissions
}

private fun defaultChannelPermissions() : Permissions {
    val permissions: Permissions = mutableMapOf()
    permissions.canWrite              = false
    permissions.canEditMessages       = false
    permissions.canEditAllMessages    = false
    permissions.canRemoveMessages     = false
    permissions.canRemoveAllMessages  = false
    permissions.canManageParticipants = true
    return permissions
}

private const val WRITE = "canWrite"
private const val EDIT = "canEditMessages"
private const val EDITALL = "canEditAllMessages"
private const val REMOVE = "canRemoveMessages"
private const val REMOVEALL = "canRemoveAllMessages"
private const val MANAGE = "canManageParticipants"