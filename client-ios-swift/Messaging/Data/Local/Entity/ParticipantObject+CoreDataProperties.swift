/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import CoreData
import VoxImplantSDK

extension ParticipantObject {
    @NSManaged public var canEditAllMessages: Bool
    @NSManaged public var canEditMessages: Bool
    @NSManaged public var canRemoveAllMessages: Bool
    @NSManaged public var canRemoveMessages: Bool
    @NSManaged public var canManageParticipants: Bool
    @NSManaged public var canWrite: Bool
    @NSManaged public var isOwner: Bool
    @NSManaged public var lastReadEventSequence: Int64
    @NSManaged public var conversation: ConversationObject
    @NSManaged public var user: UserObject
}

extension ParticipantObject: ManagedObject {
    struct ParticipantID: Equatable {
        let userID: User.ID
        let conversationID: Conversation.ID
    }
    
    var id: ParticipantID { ParticipantID(userID: user.imId, conversationID: conversation.uuid) }
    
    var converted: Participant {
        Participant(
            isOwner: isOwner,
            user: user.converted,
            permissions: Permissions(
                canWrite: canWrite,
                canEditMessages: canEditMessages,
                canEditAllMessages: canEditAllMessages,
                canRemoveMessages: canRemoveMessages,
                canRemoveAllMessages: canRemoveAllMessages,
                canManageParticipants: canManageParticipants),
            lastReadEventSequence: Int(lastReadEventSequence)
        )
    }
    
    static func makeFetchRequest(for key: ParticipantID) -> NSFetchRequest<ParticipantObject> {
        let fetchRequest: NSFetchRequest<ParticipantObject> = defaultFetchRequest
        fetchRequest.predicate = NSPredicate(
            format: "user.imId == %@ && conversation.uuid == %@",
            argumentArray: [key.userID, key.conversationID]
        )
        return fetchRequest
    }
    
    func update(from value: VIConversationParticipant) {
        canWrite = value.canWrite
        canEditMessages = value.canEditMessages
        canEditAllMessages = value.canEditAllMessages
        canRemoveMessages = value.canRemoveMessages
        canRemoveAllMessages = value.canRemoveAllMessages
        canManageParticipants = value.canManageParticipants
        isOwner = value.isOwner
        lastReadEventSequence = value.lastReadEventSequence
    }
}
