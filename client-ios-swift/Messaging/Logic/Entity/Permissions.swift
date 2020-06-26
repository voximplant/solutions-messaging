/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

struct Permissions: Equatable {
    var canWrite: Bool
    var canEditMessages: Bool
    var canEditAllMessages: Bool
    var canRemoveMessages: Bool
    var canRemoveAllMessages: Bool
    var canManageParticipants: Bool
    
    var nsDictionary: NSDictionary {
        ["canWrite": canWrite,
         "canEditMessages": canEditMessages,
         "canEditAllMessages": canEditAllMessages,
         "canRemoveMessages": canRemoveMessages,
         "canRemoveAllMessages": canRemoveAllMessages,
         "canManageParticipants": canManageParticipants
        ]
    }
    
    static func defaultForAdmin() -> Permissions {
        Permissions(
            canWrite: true,
            canEditMessages: true,
            canEditAllMessages: true,
            canRemoveMessages: true,
            canRemoveAllMessages: true,
            canManageParticipants: true
        )
    }
    
    static func defaultPermissions(for type: Conversation.ConversationType) -> Permissions {
        switch type {
        case .direct:
            return Permissions(
                canWrite: true,
                canEditMessages: true,
                canEditAllMessages: false,
                canRemoveMessages: true,
                canRemoveAllMessages: false,
                canManageParticipants: false
            )
        case .chat:
            return Permissions(
                canWrite: true,
                canEditMessages: true,
                canEditAllMessages: false,
                canRemoveMessages: true,
                canRemoveAllMessages: false,
                canManageParticipants: true
            )
        case .channel:
            return Permissions(
                canWrite: false,
                canEditMessages: false,
                canEditAllMessages: false,
                canRemoveMessages: false,
                canRemoveAllMessages: false,
                canManageParticipants: true
            )
        }
    }
}
