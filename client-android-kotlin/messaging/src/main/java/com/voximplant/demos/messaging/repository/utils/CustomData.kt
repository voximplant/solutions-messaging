package com.voximplant.demos.messaging.repository.utils

import com.voximplant.demos.messaging.utils.permissions.Permissions

typealias CustomData = MutableMap<String, Any?>

var CustomData.type: String?
    get() = this[TYPE] as String?
    set(value) = this.set(TYPE, value)

var CustomData.image: String?
    get() = this[IMAGE] as String?
    set(value) = this.set(IMAGE, value)

var CustomData.chatDescription: String?
    get() = this[DESCRIPTION] as String?
    set(value) = this.set(DESCRIPTION, value)

var CustomData.status: String?
    get() = this[STATUS] as String?
    set(value) = this.set(STATUS, value)

var CustomData.permissions: Permissions?
    @Suppress("UNCHECKED_CAST")
    get() = this[PERMISSIONS] as Permissions?
    set(value) = this.set(PERMISSIONS, value)

private const val TYPE = "type"
private const val IMAGE = "image"
private const val DESCRIPTION = "description"
private const val STATUS = "status"
private const val PERMISSIONS = "permissions"