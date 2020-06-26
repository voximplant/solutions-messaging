/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import CoreData
import VoxImplantSDK

extension MessageEventObject {
    @NSManaged public var text: String
    @NSManaged public var messageSequence: Int64
    @NSManaged public var uuid: String
    @NSManaged public var edited: Bool
    @NSManaged public var removed: Bool
    @NSManaged public var isRead: Bool
}

extension MessageEventObject: ManagedObject {
    var id: MessageEventObjectID { MessageEventObjectID(conversationID: conversation.uuid, uuid: uuid) }
    
    var converted: MessageEvent {
        MessageEvent(
            initiator: initiator.converted,
            conversation: conversation.converted,
            sequence: Int(sequence),
            message: Message(
                sequence: Int(messageSequence),
                uuid: uuid,
                text: text,
                edited: edited,
                removed: removed,
                isRead: isRead
            ),
            timestamp: timestamp
        )
    }
    
    static func makeFetchRequest(for key: MessageEventObjectID) -> NSFetchRequest<MessageEventObject> {
        let fetchRequest: NSFetchRequest<MessageEventObject> = defaultFetchRequest
        fetchRequest.predicate = NSPredicate(
            format: "conversation.uuid == %@ AND uuid == %@",
            argumentArray: [key.conversationID, key.uuid]
        )
        return fetchRequest
    }
    
    func update(from value: VIMessageEvent) {
        sequence = value.sequence
        timestamp = value.timestamp
        text = value.message.text
        messageSequence = value.message.sequence
        // If once set to true should never be set back to false
        if value.action == .editMessage { edited = true }
        if value.action == .removeMessage { removed = true }
        uuid = value.message.uuid
    }
    
    struct MessageEventObjectID: Equatable {
        let conversationID: ConversationObject.ID
        let uuid: String
    }
}
