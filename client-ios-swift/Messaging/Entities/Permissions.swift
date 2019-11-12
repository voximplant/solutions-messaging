/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

typealias Permissions = Dictionary<String, Bool>

extension Permissions {
    var canWrite: Bool {
        get { return self["canWrite"]! }
        set { self["canWrite"] = newValue }
    }
    
    var canEditMessages: Bool {
        get { return self["canEditMessages"]! }
        set { self["canEditMessages"] = newValue }
    }
    
    var canEditAllMessages: Bool {
        get { return self["canEditAllMessages"]! }
        set { self["canEditAllMessages"] = newValue }
    }
    
    var canRemoveMessages: Bool {
        get { return self["canRemoveMessages"]! }
        set { self["canRemoveMessages"] = newValue }
    }
    
    var canRemoveAllMessages: Bool {
        get { return self["canRemoveAllMessages"]! }
        set { self["canRemoveAllMessages"] = newValue }
    }
    
    var canManageParticipants: Bool {
        get { return self["canManageParticipants"]! }
        set { self["canManageParticipants"] = newValue }
    }
    
    var nsDictionary: NSDictionary {
        return self as NSDictionary
    }
    
    static func defaultForAdmin() -> Permissions {
        var permissions: Permissions = [:]
        permissions.canWrite = true
        permissions.canEditMessages = true
        permissions.canEditAllMessages = true
        permissions.canRemoveMessages = true
        permissions.canRemoveAllMessages = true
        permissions.canManageParticipants = true
        return permissions
    }
    
    static func defaultForDirect() -> Permissions {
        var permissions: Permissions = [:]
        permissions.canWrite = true
        permissions.canEditMessages = true
        permissions.canEditAllMessages = false
        permissions.canRemoveMessages = true
        permissions.canRemoveAllMessages = false
        permissions.canManageParticipants = false
        return permissions
    }
    
    static func defaultForChat() -> Permissions {
        var permissions: Permissions = [:]
        permissions.canWrite = true
        permissions.canEditMessages = true
        permissions.canEditAllMessages = false
        permissions.canRemoveMessages = true
        permissions.canRemoveAllMessages = false
        permissions.canManageParticipants = true
        return permissions
    }
    
    static func defaultForChannel() -> Permissions {
        var permissions: Permissions = [:]
        permissions.canWrite = false
        permissions.canEditMessages = false
        permissions.canEditAllMessages = false
        permissions.canRemoveMessages = false
        permissions.canRemoveAllMessages = false
        permissions.canManageParticipants = true
        return permissions
    }
}
