/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import CoreData
import VoxImplantSDK

extension ConversationObject {
    @NSManaged public var conversationDescription: String?
    @NSManaged public var isPublic: Bool
    @NSManaged public var isUber: Bool
    @NSManaged public var lastSequence: Int64
    @NSManaged public var lastReadSequence: Int64
    @NSManaged public var lastUpdatedTime: Double
    @NSManaged public var pictureName: String?
    @NSManaged public var title: String?
    @NSManaged public var type: Int16
    @NSManaged public var uuid: String
    @NSManaged public var events: NSSet
    @NSManaged public var participants: NSSet
    // Permissions
    @NSManaged public var canWrite: Bool
    @NSManaged public var canEditMessages: Bool
    @NSManaged public var canEditAllMessages: Bool
    @NSManaged public var canRemoveMessages: Bool
    @NSManaged public var canRemoveAllMessages: Bool
    @NSManaged public var canManageParticipants: Bool
}

extension ConversationObject: ManagedObject {
    var id: String { uuid }
    
    var converted: Conversation {
        Conversation(
            uuid: uuid,
            type: Conversation.ConversationType(rawValue: self.type) ?? .chat,
            title: correctTitle ?? "there must be an title",
            participants: participants.compactMap { ($0 as? ParticipantObject)?.converted },
            pictureName: correctPictureName,
            description: correctDescription,
            permissions: Permissions(
                canWrite: canWrite,
                canEditMessages: canEditMessages,
                canEditAllMessages: canEditAllMessages,
                canRemoveMessages: canRemoveMessages,
                canRemoveAllMessages: canRemoveAllMessages,
                canManageParticipants: canManageParticipants
            ),
            lastUpdated: lastUpdatedTime,
            lastSequence: Int(lastSequence),
            isPublic: isPublic,
            isUber: isUber,
            lastReadSequence: Int(lastReadSequence)
        )
    }
    
    private var correctTitle: String? {
        guard let type = Conversation.ConversationType(rawValue: self.type),
            type == .direct else {
                return self.title
        }
        
        if let participants = self.participants as? Set<ParticipantObject> {
            for participant in participants {
                if !participant.user.me { return participant.user.displayName }
            }
            return nil
        } else {
            Log.w("Failed to build correct title for conversation \(self.uuid) because no participants were found \(participants)")
            return nil
        }
    }
    
    private var correctDescription: String? {
        guard let type = Conversation.ConversationType(rawValue: self.type),
            type == .direct else {
                return conversationDescription
        }
        
        if let participants = self.participants as? Set<ParticipantObject> {
            for participant in participants {
                if !participant.user.me { return participant.user.status }
            }
            return nil
        } else {
            Log.w("Failed to build correct description for conversation \(self.uuid) because no participants were found \(participants)")
            return nil
        }
    }
    
    private var correctPictureName: String? {
        guard let type = Conversation.ConversationType(rawValue: self.type),
            type == .direct else {
                return pictureName
        }
        
        if let participants = self.participants as? Set<ParticipantObject> {
            for participant in participants {
                if !participant.user.me { return participant.user.pictureName }
            }
            return nil
        } else {
            Log.w("Failed to build correct picture name for conversation \(self.uuid) because no participants were found \(participants)")
            return nil
        }
    }
    
    static func makeFetchRequest(for key: String) -> NSFetchRequest<ConversationObject> {
        let fetchRequest: NSFetchRequest<ConversationObject> = defaultFetchRequest
        fetchRequest.predicate = NSPredicate(
            format: "uuid == %@",
            argumentArray: [key]
        )
        return fetchRequest
    }
    
    func update(from value: VIConversation) {
        uuid = value.uuid
        title = value.title
        pictureName = value.customData.image
        conversationDescription = value.customData.chatDescription
        type = value.customData.type.rawValue
        isPublic = value.isPublicJoin
        isUber = value.isUber
        if value.lastSequence > lastSequence {
            lastSequence = value.lastSequence
        }
        if value.lastUpdateTime > lastUpdatedTime {
            lastUpdatedTime = value.lastUpdateTime
        }
        canWrite = value.customData.permissions?["canWrite"] as? Bool ?? false
        canEditMessages = value.customData.permissions?["canEditMessages"] as? Bool ?? false
        canEditAllMessages = value.customData.permissions?["canEditAllMessages"] as? Bool ?? false
        canRemoveMessages = value.customData.permissions?["canRemoveMessages"] as? Bool ?? false
        canRemoveAllMessages = value.customData.permissions?["canRemoveAllMessages"] as? Bool ?? false
        canManageParticipants = value.customData.permissions?["canManageParticipants"] as? Bool ?? false
    }
}

extension ConversationObject: Predicatable {
    func satisfiesPredicate(_ predicate: String) -> Bool {
        uuid == predicate
    }
}

// MARK: Generated accessors for events
extension ConversationObject {
    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: MessengerEventObject)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: MessengerEventObject)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSSet)
}

// MARK: Generated accessors for participants
extension ConversationObject {
    @objc(addParticipantsObject:)
    @NSManaged public func addToParticipants(_ value: ParticipantObject)

    @objc(removeParticipantsObject:)
    @NSManaged public func removeFromParticipants(_ value: ParticipantObject)

    @objc(addParticipants:)
    @NSManaged public func addToParticipants(_ values: NSSet)

    @objc(removeParticipants:)
    @NSManaged public func removeFromParticipants(_ values: NSSet)
}
