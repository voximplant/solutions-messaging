/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation
import VoxImplant

#error ("Enter Voximplant account credentials")
let appName = "messaging"
let accountName = "mobiledev"
let voxDomain = ".voximplant.com"

protocol VoximplantServiceDelegate: AnyObject {
    func didReceive(conversationEvent: VIConversationEvent)
    func didReceive(messageEvent: VIMessageEvent)
    func didReceive(serviceEvent: VIConversationServiceEvent)
    func didReceive(userEvent: VIUserEvent)
}

class VoximplantService: NSObject, VIMessengerDelegate, MessagingDataSource {
    private weak var delegate: VoximplantServiceDelegate?
    
    private let messenger: VIMessenger
    
    var me: VIUser?
    private var meNeedsUpdating: Bool = false
    
    init(with messenger: VIMessenger) {
        self.messenger = messenger
        super.init()
        self.messenger.addDelegate(self)
    }
    
    func set(delegate: VoximplantServiceDelegate) {
        self.delegate = delegate
    }
    
    // MARK: - Users -
    func removeMe() {
        me = nil
        meNeedsUpdating = false
    }
    
    // MARK: - Request
    func requestMe(completion: @escaping VIUserCompletion) {
        if let me = self.me,
            !meNeedsUpdating { completion(.success(me)) }
            
        else if let myUsername = messenger.me {
            requestUser(with: myUsername) { result in
                if case .failure (let error) = result { completion(.failure(error)) }
                if case .success (let user) = result {
                    self.me = user
                    self.meNeedsUpdating = false
                    completion(.success(user))
                }
            }
        }
            
        else { completion(.failure(VoxDemoError.errorNotLoggedIn())) }
    }
    
    func requestUser(with imID: NSNumber, completion: @escaping VIUserCompletion) {
        messenger.getUserByIMId(imID, completion: VIMessengerCompletion<VIUserEvent> (success:
            { userEvent in
                completion(.success(userEvent.user)) })
            { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            })
    }
    
    func requestUser(with username: String, completion: @escaping VIUserCompletion) {
        messenger.getUserByName(username, completion: VIMessengerCompletion<VIUserEvent> (success:
            { userEvent in
                completion(.success(userEvent.user)) })
            { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            })
    }
    
    func requestUsers(with usernameArray: [String], completion: @escaping VIUserArrayCompletion) { // TODO: - check for count of usernames
        messenger.getUsersByName(usernameArray, completion: VIMessengerCompletion<NSArray> (success:
            { event in
                let userEvents = event as! [VIUserEvent]
                completion(.success(userEvents.map { $0.user }))
            })
            { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            })
    }
    
    func requestUsers(with imIDArray: [NSNumber], completion: @escaping VIUserArrayCompletion) { // TODO: - check for count of usernames
        messenger.getUsersByIMId(imIDArray, completion: VIMessengerCompletion<NSArray> (success:
            { event in
                let userEvents = event as! [VIUserEvent]
                completion(.success(userEvents.map { $0.user }))
            })
            { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            })
    }
    
    // MARK: - Edit
    func editUser(with customData: [String: NSObject], completion: @escaping VIUserCompletion) {
        messenger.editUser(withCustomData: customData, privateCustomData: nil, completion: VIMessengerCompletion<VIUserEvent> (success:
            { userEvent in
                self.me = userEvent.user
                completion(.success(userEvent.user))
            })
            { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            })
    }
    
    // MARK: - Conversations -
    // MARK: - Create
    func createConversation(with config: VIConversationConfig, completion: @escaping VIConversationCompletion) { // TODO: - Discuss
        messenger.createConversation(config, completion: VIMessengerCompletion<VIConversationEvent> (success:
            { conversationEvent in
                self.meNeedsUpdating = true
                completion(.success(conversationEvent.conversation)) })
            { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            })
    }
    
    // MARK: - Request
    func requestSingleConversation(with uuid: String, completion: @escaping VIConversationCompletion) {
        messenger.getConversation(uuid, completion: VIMessengerCompletion<VIConversationEvent> (success:
            { conversation in
                completion(.success(conversation.conversation))
            })
            { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            })
    }
    
    func requestMultipleConversations(with uuids: [String], completion: @escaping VIConversationArrayCompletion) {
        messenger.getConversations(uuids, completion: VIMessengerCompletion<NSArray> (success:
            { conversationEvents in
                let conversationEvents = conversationEvents as! [VIConversationEvent]
                let conversations = conversationEvents.map { conversationEvent in conversationEvent.conversation }
                completion(.success(conversations))
            })
            { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            })
    }
    
    func recreateConversation(with UUID: String, and config: VIConversationConfig, _ lastSequence: Int?) -> VIConversation? {
        return messenger.recreateConversation(config, uuid: UUID, lastSequence: Int64(lastSequence ?? 0), lastUpdateTime: 0, createdTime: 0)
    }
    
    // MARK: - Edit
    func edit(participants: [VIConversationParticipant], in conversation: VIConversation, completion: @escaping VIConversationEventCompletion) {
        conversation.editParticipants(participants, completion: VIMessengerCompletion<VIConversationEvent> (success:
            { conversationEvent in
                completion(.success(conversationEvent))
            })
            { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            })
    }
    
    func add(participants: [VIConversationParticipant], to conversation: VIConversation, completion: @escaping VIConversationEventCompletion) {
        conversation.addParticipants(participants, completion: VIMessengerCompletion<VIConversationEvent> (success:
            { conversationEvent in
                completion(.success(conversationEvent))
            })
            { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            })
    }
    
    func remove(participants: [VIConversationParticipant], from conversation: VIConversation, completion: @escaping VIConversationEventCompletion) {
        conversation.removeParticipants(participants, completion: VIMessengerCompletion<VIConversationEvent> (success:
            { conversationEvent in
                completion(.success(conversationEvent))
            })
            { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            })
    }
    
    func update(conversation: VIConversation, completion: @escaping VIConversationEventCompletion) {
        conversation.update(completion: VIMessengerCompletion<VIConversationEvent> (success:
            { conversationEvent in
                completion(.success(conversationEvent))
            })
            { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            })
    }
    
    func leaveConversation(with UUID: String, completion: @escaping VIConversationEventCompletion) {
        messenger.leaveConversation(UUID, completion: VIMessengerCompletion<VIConversationEvent> (success:
            { conversationEvent in
                completion(.success(conversationEvent))
            })
            { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            })
    }
    
    // MARK: - Messages -
    func sendMessage(with text: String, in conversation: VIConversation, completion: @escaping VIMessageEventCompletion) {
        conversation.sendMessage(text, payload: nil, completion: VIMessengerCompletion<VIMessageEvent> (success:
            { messageEvent in
                completion(.success(messageEvent)) })
            { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            })
    }
    
    func edit(message: VIMessage, with text: String, completion: @escaping VIMessageEventCompletion) {
        message.update(text, payload: nil, completion: VIMessengerCompletion<VIMessageEvent> (success:
            { messageEvent in
                completion(.success(messageEvent))
            })
            { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            })
    }
    
    func remove(message: VIMessage, completion: @escaping VIMessageEventCompletion) {
        message.remove(completion: VIMessengerCompletion<VIMessageEvent> (success:
            { messageEvent in
                completion(.success(messageEvent))
            })
            { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            })
    }
    
    func recreateMessage(with UUID: String, and conversationUUID: String) -> VIMessage? {
        return messenger.recreateMessage(UUID, conversation: conversationUUID, text: nil, payload: nil, sequence: 0)
    }
    
    // MARK: - Events -
    func markAsRead(sequence: Int64, in conversation: VIConversation) {
        // completion is nil and event will be sent to delegate method
        conversation.markAsRead(sequence, completion: nil)
    }
    
    func sendTyping(in conversation: VIConversation) {
        // completion is nil and event will be sent to delegate method
        conversation.typing(completion: nil)
    }
    
    func requestMessengerEvents(for conversation: VIConversation, completion: @escaping VIEventArrayCompletion) {
        conversation.retransmitEvents(to: conversation.lastSequence, count: UInt(100),completion: VIMessengerCompletion<VIRetransmitEvent> (success:
            { retransmitEvents in
                completion(.success(retransmitEvents.events))
            })
            { errorEvent in
                completion(.failure(NSError.buildError(from: errorEvent)))
            })
    }
    
    // MARK: - VIMessengerDelegate -
    func messenger(_ messenger: VIMessenger, didEditMessage event: VIMessageEvent) {
        delegate?.didReceive(messageEvent: event)
    }
    
    func messenger(_ messenger: VIMessenger, didSendMessage event: VIMessageEvent) {
        delegate?.didReceive(messageEvent: event)
    }
    
    func messenger(_ messenger: VIMessenger, didRemoveMessage event: VIMessageEvent) {
        delegate?.didReceive(messageEvent: event)
    }
    
    func messenger(_ messenger: VIMessenger, didCreateConversation event: VIConversationEvent) {
        meNeedsUpdating = true
        delegate?.didReceive(conversationEvent: event)
    }
    
    func messenger(_ messenger: VIMessenger, didRemoveConversation event: VIConversationEvent) {
        meNeedsUpdating = true
        delegate?.didReceive(conversationEvent: event)
    }
    
    func messenger(_ messenger: VIMessenger, didEditConversation event: VIConversationEvent) {
        delegate?.didReceive(conversationEvent: event)
    }
    
    func messenger(_ messenger: VIMessenger, didReceiveTypingNotification event: VIConversationServiceEvent) {
        if event.imUserId == me?.imId { return }
        delegate?.didReceive(serviceEvent: event)
    }
    
    func messenger(_ messenger: VIMessenger, didReceiveReadConfirmation event: VIConversationServiceEvent) {
        if event.imUserId == me?.imId { return }
        delegate?.didReceive(serviceEvent: event)
    }
    
    func messenger(_ messenger: VIMessenger, didEditUser event: VIUserEvent) {
        delegate?.didReceive(userEvent: event)
    }
}

// MARK: - Extensions -
fileprivate extension NSError {
    static func buildError(from errorEvent: VIErrorEvent) -> NSError {
        let description: String = errorEvent.errorDescription
        return NSError(domain: errorDomain,
                       code: errorEvent.errorCode,
                       userInfo: [NSLocalizedDescriptionKey: description])
    }
}
