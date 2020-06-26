/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import CoreData
import VoxImplantSDK

final class CoreDataController: DataBaseController {
    var userDataSource: UserDataSource { _userDataSource } // lateinit
    private var _userDataSource: UserDataSource!

    var conversationDataSource: ConversationDataSource { _conversationDataSource } // lateinit
    private var _conversationDataSource: ConversationDataSource!
    
    var eventDataSource: EventDataSource { _eventDataSource } // lateinit
    private var _eventDataSource: EventDataSource!
    
    private let persistentContainer: NSPersistentContainer
    private var backgroundContext: NSManagedObjectContext! // lateinit
    
    @discardableResult init(onceReady: @escaping (CoreDataController) -> ()) {
        persistentContainer = NSPersistentContainer(name: "MessagingStorage")
        persistentContainer.loadPersistentStores() { (description, error) in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
            self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
            self.backgroundContext = self.persistentContainer.newBackgroundContext()
            self._userDataSource = DefaultUserDataSource(context: self.persistentContainer.viewContext, controller: self)
            self._conversationDataSource = DefaultConversationDataSource(context: self.persistentContainer.viewContext, controller: self)
            self._eventDataSource = DefaultEventDataSource(context: self.persistentContainer.viewContext)
            
            onceReady(self)
        }
    }
    
    // MARK: - User -
    var me: User? {
        (try? fetch(with: NSPredicate(format: "me == YES")) as [UserObject])?.first?.converted
    }
    
    func saveUser(_ viUser: VIUser, me: Bool = false, completion: @escaping (Error?) -> Void) {
        backgroundContext.perform({
            if let object: UserObject = try? self.fetch(by: viUser.imId.int64Value) {
                object.update(from: viUser)
            } else {
                let object: UserObject = UserObject.insert(into: self.backgroundContext)
                object.update(from: viUser)
                object.me = me
            }
            try self.save()
        }, completion: completion)
    }
        
    func updateUser(_ viUser: VIUser, completion: @escaping (Error?) -> Void) {
        backgroundContext.perform({
            if let object: UserObject = try? self.fetch(by: viUser.imId.int64Value) {
                object.update(from: viUser)
            } else {
                completion(CoreDataError.dataNotFound(UserObject.self))
            }
            try self.save()
        }, completion: completion)
    }
    
    // MARK: - Conversation -
    func saveConversation(
        _ viConversation: VIConversation,
        completion: @escaping (Error?) -> Void
    ) {
        backgroundContext.perform({
            if let object: ConversationObject = try? self.fetch(by: viConversation.uuid) {
                object.update(from: viConversation)
                
                let oldImIds = object.participants.compactMap {
                    ($0 as? ParticipantObject)?.user.imId
                }
                
                try oldImIds.forEach { id in
                    let participant: ParticipantObject = try self.fetch(
                        by: ParticipantObject.ID(
                            userID: id, conversationID:
                            viConversation.uuid
                        )
                    )
                    self.backgroundContext.delete(participant)
                }
                
                object.addToParticipants(
                    NSSet(array: try viConversation.participants
                        .map { (viParticipant: VIConversationParticipant) -> ParticipantObject in
                            let participant
                                = ParticipantObject.insert(into: self.backgroundContext)
                            participant.update(from: viParticipant)
                            participant.conversation = object
                            participant.user = try self.fetch(by: viParticipant.imUserId.int64Value)
                            return participant
                        }
                    )
                )
                if let participants = object.participants as? Set<ParticipantObject> {
                    participants.forEach {
                        if object.lastReadSequence < $0.lastReadEventSequence {
                            object.lastReadSequence = $0.lastReadEventSequence
                        }
                    }
                }
            } else {
                let object = ConversationObject.insert(into: self.backgroundContext)
                object.update(from: viConversation)
                object.addToParticipants(
                    NSSet(array: try viConversation.participants
                        .map { (viParticipant: VIConversationParticipant) -> ParticipantObject in
                            let participant = ParticipantObject.insert(into: self.backgroundContext)
                            participant.update(from: viParticipant)
                            participant.conversation = object
                            participant.user = try self.fetch(by: viParticipant.imUserId.int64Value)
                            return participant
                        }
                    )
                )
                if let participants = object.participants as? Set<ParticipantObject> {
                    participants.forEach {
                        if object.lastReadSequence < $0.lastReadEventSequence {
                            object.lastReadSequence = $0.lastReadEventSequence
                        }
                    }
                }
            }
            try self.save()
        }, completion: completion)
    }
    
    func updateConversationParticipants(
        _ viConversation: VIConversation,
        completion: @escaping (Error?) -> Void
    ) {
        backgroundContext.perform({
            guard let conversation: ConversationObject = try? self.fetch(by: viConversation.uuid)
                else {
                    self.saveConversation(viConversation, completion: completion)
                    return
            }
            let oldImIds = conversation.participants.compactMap {
                ($0 as? ParticipantObject)?.user.imId
            }
            try oldImIds.forEach { id in
                let participant: ParticipantObject = try self.fetch(
                    by: ParticipantObject.ID(
                        userID: id,
                        conversationID: viConversation.uuid
                    )
                )
                self.backgroundContext.delete(participant)
            }
            conversation.addToParticipants(
                NSSet(array: try viConversation.participants
                    .map { (viParticipant: VIConversationParticipant) -> ParticipantObject in
                        let participant = ParticipantObject.insert(into: self.backgroundContext)
                        participant.update(from: viParticipant)
                        participant.conversation = conversation
                        participant.user = try self.fetch(by: viParticipant.imUserId.int64Value)
                        return participant
                    }
                )
            )
            try self.save()
        }, completion: completion)
    }
    
    func updateConversation(
        _ viConversation: VIConversation,
        completion: @escaping (Error?) -> Void
    ) {
        backgroundContext.perform({
            let conversation: ConversationObject = try self.fetch(by: viConversation.uuid)
            conversation.update(from: viConversation)
            try self.save()
        }, completion: completion)
    }
    
    func removeConversation(
        _ id: ConversationObject.ID,
        completion: @escaping (Error?) -> Void
    ) {
        backgroundContext.perform({
            let conversation: ConversationObject = try self.fetch(by: id)
            self.backgroundContext.delete(conversation)
            try self.save()
        }, completion: completion)
    }
    
    // MARK: - Participant -
    func getParticipant(id: ParticipantObject.ID) -> Participant? {
        getObject(of: ParticipantObject.self, by: id)
    }
    
    func updateLastReadSequence(
        participantID: ParticipantObject.ID, sequence: Int64,
        completion: @escaping (Error?) -> Void
    ) {
        backgroundContext.perform({
            let conversation: ConversationObject = try self.fetch(by: participantID.conversationID)
            conversation.lastReadSequence = sequence
            let object: ParticipantObject = try self.fetch(by: participantID)
            if object.lastReadEventSequence < sequence {
                object.lastReadEventSequence = sequence
            }
            try self.save()
        }, completion: completion)
    }
            
    // MARK: - Events
    func process(viEvents: [VIMessengerEvent], completion: @escaping (Error?) -> Void) {
        forEach(data: viEvents, method: processEvent(_:completion:), completion: completion)
    }
    
    func processEvent(_ viEvent: VIMessengerEvent, completion: @escaping (Error?) -> Void) {
        backgroundContext.perform({
            if let viMessageEvent = viEvent as? VIMessageEvent {
                try self.processEvent(viMessageEvent)
            }
            if let viConversationEvent = viEvent as? VIConversationEvent {
                try self.saveEvent(viConversationEvent)
            }
        }, completion: completion)
    }
    
    func updateEventsReadMark(
        conversation: String,
        sequence lastReadSequence: Int64,
        completion: @escaping (Error?) -> Void
    ) {
        backgroundContext.perform({
            let predicate = NSPredicate(
                format: "conversation.uuid == %@ AND messageSequence <= %@",
                argumentArray: [conversation, lastReadSequence]
            )
            let events: [MessageEventObject] = try self.fetch(with: predicate)
            events.forEach { if !$0.isRead { $0.isRead = true } }
            try self.save()
        }, completion: completion)
    }
    
    private func saveEvent(_ viConversationEvent: VIConversationEvent) throws {
        if let _: ConversationEventObject = try? fetch(by:
            ConversationEventObject.ID(
                conversationID: viConversationEvent.conversation.uuid,
                sequence: viConversationEvent.sequence
        )) {
            Log.w("Attempted to save already stored conversation event \(viConversationEvent)")
            return
        }
        
        guard let userID = viConversationEvent.imUserId else {
            throw CoreDataError.dataProcessingError("userID was nil on saveEvent")
        }
        
        let conversation: ConversationObject = try fetch(by: viConversationEvent.conversation.uuid)
        let object = ConversationEventObject.insert(into: backgroundContext)
        object.update(from: viConversationEvent)
        object.conversation = conversation
        object.initiator = try fetch(by: userID.int64Value)
        conversation.addToEvents(object)
        try save()
    }
    
    private func processEvent(_ viMessageEvent: VIMessageEvent) throws {
        guard let message: MessageEventObject =
            try? self.fetch(by: MessageEventObject.ID(
                conversationID: viMessageEvent.message.conversation,
                uuid: viMessageEvent.message.uuid)
            ) else {
                try self.saveMessage(viMessageEvent)
                return
        }
        
        // If message is already removed, no other actions with it allowed
        if message.removed {
            return
        }
        
        // If message is already edited, it might be outdated, update happens in the `editMessage`
        if message.edited {
            try self.editMessage(message, viMessageEvent: viMessageEvent)
            return
        }
        
        switch viMessageEvent.action {
        case .sendMessage:
            try self.saveMessage(viMessageEvent)
        case .editMessage:
            try self.editMessage(message, viMessageEvent: viMessageEvent)
        case .removeMessage:
            try self.removeMessage(message)
        default:
            break
        }
    }
    
    func updateConversationLastSequence(
        _ id: ConversationObject.ID,
        lastUpdateTime: TimeInterval,
        lastSequence: Int64,
        completion: @escaping (Error?) -> Void
    ) {
        backgroundContext.perform({
            let object: ConversationObject = try self.fetch(by: id)
            object.lastUpdatedTime = lastUpdateTime
            object.lastSequence = lastSequence
            try self.save()
        }, completion: completion)
    }
    
    private func saveMessage(_ viMessageEvent: VIMessageEvent) throws {
        if let _: MessageEventObject =
            try? self.fetch(by: MessageEventObject.ID(
                conversationID: viMessageEvent.message.conversation,
                uuid: viMessageEvent.message.uuid)
            ) {
            Log.w("Attempted to save already stored message event \(viMessageEvent)")
            return
        } 
        
        guard let initiatorID = viMessageEvent.imUserId?.int64Value else {
            Log.w("viMessageEvent.imUserId was nil")
            throw CoreDataError.dataProcessingError("viMessageEvent.imUserId was nil")
        }
        
        let conversation: ConversationObject = try self.fetch(by: viMessageEvent.message.conversation)

        let object = MessageEventObject.insert(into: self.backgroundContext)
        object.update(from: viMessageEvent)
        object.conversation = conversation
        
        var lastRead = 1
        if let participants = object.conversation.participants as? Set<ParticipantObject> {
            participants.forEach { participant in
                if !participant.user.me && lastRead < participant.lastReadEventSequence {
                    lastRead = Int(participant.lastReadEventSequence)
                }
            }
        }
        
        object.isRead = lastRead >= viMessageEvent.message.sequence
        object.initiator = try self.fetch(by: initiatorID)
        
        conversation.addToEvents(object)
        
        try self.save()
    }
        
    private func editMessage(_ message: MessageEventObject, viMessageEvent: VIMessageEvent) throws {
        // In case we've already stored more recent event
        if message.edited && message.messageSequence > viMessageEvent.sequence {
            return
        }
        // In case we've already received remove message event
        if message.removed {
            return
        }
        message.text = viMessageEvent.message.text
        message.edited = true
        try save()
    }
    
    private func removeMessage(_ message: MessageEventObject) throws {
        message.removed = true
        try save()
    }
    
    // MARK: - Cleanable -
    func clean(completion: @escaping (Error?) -> Void) {
        backgroundContext.perform ({
            try self.deleteAllData(MessengerEventObject.self)
            try self.deleteAllData(ParticipantObject.self)
            try self.deleteAllData(ConversationObject.self)
            try self.deleteAllData(UserObject.self)
            self.eventDataSource.cleanCache()
            try self.save()
            Log.i("Clean completed")
        }, completion: completion)
    }
    
    // MARK: - Utils -
    private func deleteAllData<Object>(_ entity: Object.Type) throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: String(describing: entity.self))
        fetchRequest.returnsObjectsAsFaults = false
        let results = try backgroundContext.fetch(fetchRequest)
        for object in results {
            guard let objectData = object as? NSManagedObject else { continue }
            backgroundContext.delete(objectData)
        }
    }
    
    func getObject<Object: ManagedObject>(of type: Object.Type, by key: Object.ID) -> Object.ResultType? {
        do {
            let object: Object? = try fetch(by: key)
            return object?.converted
        } catch (let error) {
            Log.e("Get object \(Object.self) error - \(error.localizedDescription)")
            return nil
        }
    }
    
    private func fetch<Object: ManagedObject>(by key: Object.ID) throws -> Object {
        let fetchResult = try backgroundContext.fetch(Object.makeFetchRequest(for: key))
        if fetchResult.count > 1 { Log.w("Fetched more users than expected!") }
        if let object = fetchResult.first {
            return object
        } else {
            throw CoreDataError.dataNotFound(Object.self)
        }
    }
    
    private func fetch<Object: ManagedObject>(with predicate: NSPredicate? = nil) throws -> [Object] {
        let fetchRequest: NSFetchRequest<Object> = Object.defaultFetchRequest
        fetchRequest.predicate = predicate
        return try backgroundContext.fetch(fetchRequest)
    }
    
    private func save() throws {
        if backgroundContext.hasChanges {
            try backgroundContext.save()
        }
    }
}

fileprivate extension NSManagedObjectContext {
    func perform(_ code: @escaping () throws -> Void, completion: @escaping (Error?) -> Void) {
        self.perform {
            do {
                try code()
                completion(nil)
            } catch let error {
                completion(error)
            }
        }
    }
}
