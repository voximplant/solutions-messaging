/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import CoreData
import VoxImplantSDK

extension ConversationEventObject {
    @NSManaged public var action: Int16
}

extension ConversationEventObject: ManagedObject {
    var id: ConversationEventObjectID {
        ConversationEventObjectID(conversationID: conversation.uuid, sequence: sequence)
    }
    
    var converted: ConversationEvent {
        ConversationEvent(
            initiator: initiator.converted,
            conversation: conversation.converted,
            sequence: Int(sequence),
            action: ConversationEvent.ConversationEventAction(rawValue: action) ?? .addParticipants
        )
    }
    
    static func makeFetchRequest(for key: ConversationEventObjectID) -> NSFetchRequest<ConversationEventObject> {
        let fetchRequest: NSFetchRequest<ConversationEventObject> = defaultFetchRequest
        fetchRequest.predicate = NSPredicate(
            format: "conversation.uuid == %@ AND sequence == %@",
            argumentArray: [key.conversationID, key.sequence]
        )
        return fetchRequest
    }
    
    func update(from value: VIConversationEvent) {
        sequence = value.sequence
        timestamp = value.timestamp
        action = translateConversationAction(from: value.action).rawValue
    }
    
    private func translateConversationAction(from viAction: VIMessengerAction) -> ConversationEvent.ConversationEventAction {
        switch viAction {
        case .addParticipants    : return .addParticipants
        case .editParticipants   : return .editParticipants
        case .removeParticipants : return .removeParticipants
        case .editConversation   : return .editConversation
        case .joinConversation   : return .joinConversation
        case .leaveConversation  : return .leaveConversation
        case .createConversation : return .createConversation
        case .removeConversation : return .removeConversation
        default                  : return .addParticipants
        }
    }
    
    struct ConversationEventObjectID: Equatable {
        let conversationID: ConversationObject.ID
        let sequence: Int64
    }
}
