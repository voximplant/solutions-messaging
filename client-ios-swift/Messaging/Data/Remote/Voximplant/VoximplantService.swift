/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

final class VoximplantService: NSObject, VIMessengerDelegate, VoximplantDataSource {
    private let messenger: VIMessenger
    weak var delegate: VoximplantEventDelegate?
    var myUsername: String? { messenger.me }
    
    init(with messenger: VIMessenger) {
        self.messenger = messenger
        super.init()
        self.messenger.addDelegate(self)
    }
    
    // MARK: - Users -
    // MARK: - Request
    func requestUser(with username: String, completion: @escaping VIUserCompletion) {
        messenger.getUserByName(
            username,
            completion: VIMessengerCompletion<VIUserEvent> (
                success: { completion(.success($0.user)) },
                failure: { completion(.failure(NSError(from: $0))) }
            )
        )
    }
    
    func requestUsers(with usernames: [String], completion: @escaping VIUserArrayCompletion) {
        messenger.getUsersByName(
            usernames,
            completion: VIMessengerCompletion<NSArray> (
                success: { completion(.success($0.compactMap { ($0 as? VIUserEvent)?.user })) },
                failure: { completion(.failure(NSError(from: $0))) }
            )
        )
    }
    
    // MARK: - Edit
    func editUser(with customData: [String: NSObject], completion: @escaping VIUserCompletion) {
        messenger.editUser(
            withCustomData: customData,
            privateCustomData: nil,
            completion: VIMessengerCompletion<VIUserEvent> (
                success: { completion(.success($0.user)) },
                failure: { completion(.failure(NSError(from: $0))) }
            )
        )
    }
    
    // MARK: - Conversations -
    // MARK: - Create
    func createConversation(
        with config: VIConversationConfig,
        completion: @escaping VIConversationEventCompletion
    ) {
        messenger.createConversation(
            config,
            completion: VIMessengerCompletion<VIConversationEvent> (
                success: { completion(.success($0)) },
                failure: { completion(.failure(NSError(from: $0))) }
            )
        )
    }
    
    // MARK: - Request
    func requestConversations(
        with uuids: [String],
        completion: @escaping VIConversationArrayCompletion
    ) {
        messenger.getConversations(
            uuids,
            completion: VIMessengerCompletion<NSArray> (
                success: { completion(.success(
                    $0.compactMap { ($0 as? VIConversationEvent)?.conversation }))
                },
                failure: { completion(.failure(NSError(from: $0))) }
            )
        )
    }
    
    // MARK: - Recreate
    func recreateConversation(
        with UUID: String,
        and config: VIConversationConfig
    ) -> VIConversation? {
        messenger.recreateConversation(
            config, uuid: UUID, lastSequence: 0,
            lastUpdateTime: 0, createdTime: 0
        )
    }
    
    // MARK: - Edit
    func editParticipants(
        _ participants: [VIConversationParticipant],
        in conversation: VIConversation,
        completion: @escaping VIConversationEventCompletion
    ) {
        conversation.editParticipants(
            participants,
            completion: VIMessengerCompletion<VIConversationEvent> (
                success: { completion(.success($0)) },
                failure: { completion(.failure(NSError(from: $0))) }
            )
        )
    }
    
    func addParticipants(
        _ participants: [VIConversationParticipant],
        to conversation: VIConversation,
        completion: @escaping VIConversationEventCompletion
    ) {
        conversation.addParticipants(
            participants,
            completion: VIMessengerCompletion<VIConversationEvent> (
                success: { completion(.success($0)) },
                failure: { completion(.failure(NSError(from: $0))) }
            )
        )
    }
    
    func removeParticipants(
        _ participants: [VIConversationParticipant],
        from conversation: VIConversation,
        completion: @escaping VIConversationEventCompletion
    ) {
        conversation.removeParticipants(
            participants,
            completion: VIMessengerCompletion<VIConversationEvent> (
                success: { completion(.success($0)) },
                failure: { completion(.failure(NSError(from: $0))) }
            )
        )
    }
    
    func updateConversation(
        _ conversation: VIConversation,
        completion: @escaping VIConversationEventCompletion
    ) {
        conversation.update(
            completion: VIMessengerCompletion<VIConversationEvent> (
                success: { completion(.success($0)) },
                failure: { completion(.failure(NSError(from: $0))) }
            )
        )
    }
    
    // MARK: - Leave
    func leaveConversation(_ uuid: String, completion: @escaping VIConversationEventCompletion) {
        messenger.leaveConversation(
            uuid,
            completion: VIMessengerCompletion<VIConversationEvent> (
                success: { completion(.success($0)) },
                failure: { completion(.failure(NSError(from: $0))) }
            )
        )
    }
    
    // MARK: - Messages -
    func sendMessage(
        text: String,
        to conversation: VIConversation,
        completion: @escaping VIMessageEventCompletion
    ) {
        conversation.sendMessage(
            text,
            payload: nil,
            completion: VIMessengerCompletion<VIMessageEvent> (
                success: { completion(.success($0)) },
                failure: { completion(.failure(NSError(from: $0))) }
            )
        )
    }
    
    func editMessage(
        _ message: VIMessage,
        with text: String,
        completion: @escaping VIMessageEventCompletion
    ) {
        message.update(
            text,
            payload: nil,
            completion: VIMessengerCompletion<VIMessageEvent> (
                success: { completion(.success($0)) },
                failure: { completion(.failure(NSError(from: $0))) }
            )
        )
    }
    
    func removeMessage(_ message: VIMessage, completion: @escaping VIMessageEventCompletion) {
        message.remove(
            completion: VIMessengerCompletion<VIMessageEvent> (
                success: { completion(.success($0)) },
                failure: { completion(.failure(NSError(from: $0))) }
            )
        )
    }
    
    func recreateMessage(_ UUID: String, conversation conversationUUID: String) -> VIMessage? {
        messenger.recreateMessage(UUID, conversation: conversationUUID,
                                  text: nil, payload: nil, sequence: 0)
    }
    
    // MARK: - Events -
    func markAsRead(
        sequence: Int64,
        in conversation: VIConversation,
        completion: @escaping (Error?) -> Void
    ) {
        conversation.markAsRead(
            sequence,
            completion: VIMessengerCompletion<VIConversationServiceEvent> (
                success: { _ in completion(nil) },
                failure: { completion(NSError(from: $0)) }
            )
        )
    }
    
    func sendTyping(in conversation: VIConversation) {
        conversation.typing(
            completion: VIMessengerCompletion<VIConversationServiceEvent> (
                success: { _ in Log.i("Successfully sent typing to \(conversation.uuid)")},
                failure: {
                    Log.w("Failed to send typing to \(conversation.uuid) with error \($0.errorDescription)")
                }
            )
        )
    }
    
    func requestMessengerEvents(
        for conversation: VIConversation,
        events sequenceArray: [Int64],
        completion: @escaping VIEventArrayCompletion
    ) {
        guard let startSequence = sequenceArray.first,
            let endSequence = sequenceArray.last,
            startSequence >= 1,
            endSequence <= conversation.lastSequence else {
                Log.e("Incorrect request to SDK via requestMessengerEvents with \(sequenceArray), returning empty array")
                completion(.success([]))
                return
        }
        conversation.retransmitEvents(
            from: startSequence,
            to: endSequence,
            completion: VIMessengerCompletion<VIRetransmitEvent> (
                success: { completion(.success($0.events)) },
                failure: { completion(.failure(NSError(from: $0))) }
            )
        )
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
        delegate?.didReceive(conversationEvent: event)
    }
    
    func messenger(_ messenger: VIMessenger, didRemoveConversation event: VIConversationEvent) {
        delegate?.didReceive(conversationEvent: event)
    }
    
    func messenger(_ messenger: VIMessenger, didEditConversation event: VIConversationEvent) {
        delegate?.didReceive(conversationEvent: event)
    }
    
    func messenger(_ messenger: VIMessenger,
                   didReceiveTypingNotification event: VIConversationServiceEvent) {
        delegate?.didReceive(serviceEvent: event)
    }
    
    func messenger(_ messenger: VIMessenger,
                   didReceiveReadConfirmation event: VIConversationServiceEvent) {
        delegate?.didReceive(serviceEvent: event)
    }
    
    func messenger(_ messenger: VIMessenger, didEditUser event: VIUserEvent) {
        delegate?.didReceive(userEvent: event)
    }
}

// MARK: - Utils -
fileprivate extension NSError {
    convenience init(from event: VIErrorEvent) {
        self.init(
            domain: Bundle.main.bundleIdentifier ?? "Messaging",
            code: event.errorCode,
            userInfo: [NSLocalizedDescriptionKey: event.errorDescription]
        )
    }
}
