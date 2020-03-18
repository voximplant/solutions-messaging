/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation
import VoxImplantSDK

final class MessagingRepository: Repository, VoximplantServiceDelegate {
    private weak var delegate: RepositoryDelegate?
    
    private let voxAPIService: APIService = VoxAPIService()
    private let remoteDataSource: MessagingDataSource
    private let localDataSource: MessagingDataSource // TODO: Your DataBase
    
    private let builder: ModelBuilderProtocol = ModelBuilder()
    
    var me: User? {
        guard let me = remoteDataSource.me else { return nil }
        return builder.buildUser(from: me)
    }
    
    init(remote: MessagingDataSource, local: MessagingDataSource) {
        self.remoteDataSource = remote
        self.localDataSource = local
        self.remoteDataSource.set(delegate: self)
    }
    
    func set(delegate: RepositoryDelegate) {
        self.delegate = delegate
    }
    
    // MARK: - Users -
    func removeMe() {
        remoteDataSource.removeMe()
    }
    
    // MARK: - Request
    func requestUser(with imID: NSNumber, completion: @escaping UserCompletion) {
        remoteDataSource.requestUser(with: imID) { result in
            if case .failure (let error) = result { completion(.failure(error)) }
            if case .success (let viUser) = result {
                completion(.success( self.builder.buildUser(from: viUser)))
            }
        }
    }
    
    func requestUsers(with imIDs: [NSNumber], completion: @escaping UserArrayCompletion) {
        self.remoteDataSource.requestUsers(with: imIDs) { result in
            if case .failure (let error) = result { completion(.failure(error)) }
            if case .success (let viUsers) = result {
                completion(.success(viUsers.map { self.builder.buildUser(from: $0) } ))
            }
        }
    }
    
    func requestAllUsers(completion: @escaping UserArrayCompletion) {
        voxAPIService.getVoxUsernames { apiResult in
            if case .failure (let error) = apiResult { completion(.failure(error)) }
            if case .success (let usernameArray) = apiResult {
                
                let fullUsernameArray = usernameArray.compactMap { $0.stringWithAccAndAppDomains }
                
                self.remoteDataSource.requestUsers(with: fullUsernameArray) { result in
                    if case .failure (let error) = result { completion(.failure(error)) }
                    if case .success (let viUserArray) = result {
                        completion(.success(viUserArray.map { self.builder.buildUser(from: $0) } ))
                    }
                }
            }
        }
    }
    
    // MARK: - Edit
    func editUser(with profilePictureName: String?, and status: String?, completion: @escaping UserCompletion) {
        var customData: CustomData = [:]
        if let pictureName = profilePictureName { customData.image = pictureName as NSString }
        if let status = status { customData.status = status as NSString }

        remoteDataSource.editUser(with: customData) { result in
            if case .failure (let error) = result { completion(.failure(error)) }
            if case .success (let viUser) = result { completion(.success(self.builder.buildUser(from: viUser))) }
        }
    }
    
    func remove(message: Message, completion: @escaping MessageEventCompletion) {
        guard let viMessage = remoteDataSource.recreateMessage(with: message.uuid, and: message.conversation)
            else {
                completion(.failure(VoxDemoError.errorWrongUUID()))
                return
        }
        guard let me = self.me
            else {
                completion(.failure(VoxDemoError.errorNotLoggedIn()))
                return
        }
        
        remoteDataSource.remove(message: viMessage) { result in
            if case .failure (let error) = result { completion(.failure(error)) }
            if case .success (let viEvent) = result {
                let event = self.builder.buildMessageEvent(with: viEvent, and: me)
                completion(.success(event))
            }
        }
    }
    
    // MARK: - Conversations -
    // MARK: - Request
    func requestMyConversations(completion: @escaping ConversationArrayCompletion) { // TODO: refactor
        remoteDataSource.requestMe { result in
            if case .failure (let error) = result { completion(.failure(error)) }
            if case .success (let viUser) = result {
                if let list = viUser.conversationList {
                    
                    if list.isEmpty {
                        completion(.success([]))
                        return
                    }
                    
                    let conversationRequestChunk = 5
                    let withRemainder = list.count % conversationRequestChunk > 0
                    let numberOfIterations = withRemainder
                        ? list.count / conversationRequestChunk + 1
                        : list.count / conversationRequestChunk
                    
                    let group = DispatchGroup()
                    
                    var conversations: [Conversation] = [] {
                        didSet {
                            if conversations.count % conversationRequestChunk == 0 || conversations.count == list.count {
                                group.leave()
                            }
                        }
                    }
                    
                    let failureCompletion: (Error) -> Void = { error in
                        group.leave()
                        completion(.failure(error))
                    }

                    DispatchQueue.concurrentPerform(iterations: numberOfIterations) { iteration in
                        group.enter()
                        
                        let min = iteration * conversationRequestChunk
                        var max = min + (conversationRequestChunk - 1)
                        while max >= list.count { max -= 1 }
                        
                        let croppedArray = Array(list[min...max])
                        
                        self.remoteDataSource.requestMultipleConversations(with: croppedArray) { result in
                            if case .failure (let error) = result { failureCompletion(error) }
                            if case .success (let viConversations) = result {
                                
                                viConversations.forEach { viConversation in
                                    if viConversation.isDirect {
                                        
                                        var participantImIDArray: [NSNumber] = []
                                        
                                        viConversation.participants.forEach { participantImIDArray.append($0.imUserId) }
                                        
                                        self.requestUsers(with: participantImIDArray) { result in
                                            if case .failure = result {
                                                conversations.append(self.builder.buildConversation(from: viConversation, and: [] as [User]))     
                                            }
                                            if case .success (let users) = result {
                                                conversations.append(self.builder.buildConversation(from: viConversation, and: users))
                                            }
                                        }
                                    } else {
                                        DispatchQueue.main.async {
                                            conversations.append(self.builder.buildConversation(from: viConversation, and: [] as [User]))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    group.notify(queue: .main) {
                        completion(.success(conversations))
                    }
                } else { completion(.failure(VoxDemoError.errorAcessDenied())) }
            }
        }
    }
    
    func requestConversation(with uuid: String, completion: @escaping ConversationCompletion) {
        remoteDataSource.requestSingleConversation(with: uuid) { result in
            if case .failure (let error) = result { completion(.failure(error)) }
            if case .success (let viConversation) = result {
                
                let participantImIDArray = viConversation.participants.map { $0.imUserId }
                
                self.requestUsers(with: participantImIDArray) { result in
                    if case .failure (let error) = result { completion(.failure(error)) }
                    if case .success (let viUsers) = result {
                        completion(.success(self.builder.buildConversation(from: viConversation, and: viUsers)))
                    }
                }
            }
        }
    }
    
    // MARK: - Create
    func createDirectConversation(with user: User, completion: @escaping ConversationCompletion) { // TODO: - refactor
        guard let me = self.me
            else {
                completion(.failure(VoxDemoError.errorNotLoggedIn()))
                return
        }
        
        let config = VIConversationConfig()
        config.title = ""
        config.isDirect = true
        config.isUber = false
        config.isPublicJoin = false
        config.participants = [builder.buildVIParticipant(with: user.imID, for: .direct),
                               builder.buildVIParticipant(with: me.imID, for: .direct)]
        config.customData.type = ConversationType.direct.customDataValue
        config.customData.permissions = ConversationType.direct.defaultPermissions.nsDictionary
        createConversation(with: config, completion)
    }
    
    func createGroupConversation(with title: String, and userModelArray: [User], description: String, pictureName: String?,
                                 isPublic: Bool, isUber: Bool, completion: @escaping ConversationCompletion) {
        let config = VIConversationConfig()
        config.title = title
        config.isDirect = false
        config.isUber = isUber
        config.isPublicJoin = isPublic
        config.participants = userModelArray.map { self.builder.buildVIParticipant(with: $0.imID, for: .chat) }
        config.customData = self.builder.buildCustomData(for: ConversationType.chat, pictureName, and: description)
        createConversation(with: config, completion)
    }
    
    func createChannel(with title: String, and userModelArray: [User], description: String,
                       pictureName: String?, completion: @escaping ConversationCompletion) {
        let config = VIConversationConfig()
        config.title = title
        config.isDirect = false
        config.isUber = false
        config.isPublicJoin = true
        config.participants = userModelArray.map { self.builder.buildVIParticipant(with: $0.imID, for: .channel) }
        config.customData = self.builder.buildCustomData(for: ConversationType.channel, pictureName, and: description)
        createConversation(with: config, completion)
    }
    
    private func createConversation(with config: VIConversationConfig, _ completion: @escaping ConversationCompletion) {
        
        remoteDataSource.createConversation(with: config) { result in
            if case .failure (let error) = result { completion(.failure(error)) }
            if case .success (let viConversation) = result {
                
                let participantImIDArray = viConversation.participants.map { $0.imUserId }
                
                self.requestUsers(with: participantImIDArray) { result in
                    if case .failure (let error) = result { completion(.failure(error)) }
                    if case .success (let users) = result {
                        completion(.success(self.builder.buildConversation(from: viConversation, and: users)))
                    }
                }
            }
        }
    }
    
    // MARK: - Edit
    func add(participants: [User], to conversation: Conversation, completion: @escaping ConversationCompletion) {
        guard let viConversation = remoteDataSource.recreateConversation(with: conversation.uuid,
                                                                         and: self.builder.buildConfig(for: conversation), nil)
            else {
                completion(.failure(VoxDemoError.errorWrongUUID()))
                return
        }
        
        let viParticipants = participants.map { VIConversationParticipant(imUserId: $0.imID) }
        
        self.remoteDataSource.add(participants: viParticipants, to: viConversation) { result in
            if case .failure (let error) = result { completion(.failure(error)) }
            if case .success (let viEvent) = result {
                
                var updatedUsers = conversation.participants.map { $0.user }
                updatedUsers.append(contentsOf: participants)
                
                completion(.success(self.builder.buildConversation(from: viEvent.conversation, and: updatedUsers)))
            }
        }
    }
    
    func edit(participants: [Participant], in conversation: Conversation, completion: @escaping EmptyCompletion) {
        guard let viConversation = remoteDataSource.recreateConversation(with: conversation.uuid,
                                                                         and: self.builder.buildConfig(for: conversation), nil)
            else {
                completion(.failure(VoxDemoError.errorWrongUUID()))
                return
        }
        
        let viParticipants = participants.map { builder.buildVIParticipant(from: $0) }
        
        remoteDataSource.edit(participants: viParticipants, in: viConversation) { result in
            if case .failure (let error) = result { completion(.failure(error)) }
            if case .success = result { completion(.success(())) }
        }
    }
    
    func remove(participant: User, from conversation: Conversation, completion: @escaping EmptyCompletion) {
        guard let viConversation = remoteDataSource.recreateConversation(with: conversation.uuid,
                                                                         and: self.builder.buildConfig(for: conversation), nil)
            else {
                completion(.failure(VoxDemoError.errorWrongUUID()))
                return
        }
        
        let viParticipant = VIConversationParticipant(imUserId: participant.imID)
        
        remoteDataSource.remove(participants: [viParticipant], from: viConversation) { result in
            if case .failure (let error) = result { completion(.failure(error)) }
            if case .success = result { completion(.success(())) }
        }
    }
    
    func update(conversation: Conversation, title: String, description: String?, pictureName: String?, isPublic: Bool?,
                completion: @escaping EmptyCompletion) {
        guard let viConversation = remoteDataSource.recreateConversation(with: conversation.uuid,
                                                                         and: self.builder.buildConfig(for: conversation), nil)
            else {
                completion(.failure(VoxDemoError.errorWrongUUID()))
                return
        }
        
        viConversation.title = title
        if let pictureName = pictureName as NSString? { viConversation.customData.image = pictureName }
        if let description = description as NSString? { viConversation.customData.chatDescription = description }
        if let isPublic = isPublic { viConversation.isPublicJoin = isPublic }
        
        remoteDataSource.update(conversation: viConversation) { result in
            if case .failure (let error) = result { completion(.failure(error)) }
            if case .success = result { completion(.success(())) }
        }
    }
    
    func update(conversation: Conversation, permissions: Permissions, completion: @escaping EmptyCompletion) {
        guard let viConversation = remoteDataSource.recreateConversation(with: conversation.uuid,
                                                                         and: self.builder.buildConfig(for: conversation), nil)
            else {
                completion(.failure(VoxDemoError.errorWrongUUID()))
                return
        }
        
        viConversation.customData.permissions = permissions.nsDictionary
        
        remoteDataSource.update(conversation: viConversation) { result in
            if case .failure (let error) = result { completion(.failure(error)) }
            if case .success = result { completion(.success(())) }
        }
    }
    
    func leave(conversation: Conversation, completion: @escaping EmptyCompletion) {
        remoteDataSource.leaveConversation(with: conversation.uuid) { result in
            if case .failure (let error) = result { completion(.failure(error)) }
            if case .success = result { completion(.success(())) }
        }
    }
    
    // MARK: - Messages -
    func sendMessage(with text: String, in conversation: Conversation, completion: @escaping MessageEventCompletion) {
        guard let viConversation = remoteDataSource.recreateConversation(with: conversation.uuid,
                                                                         and: self.builder.buildConfig(for: conversation), nil)
            else {
                completion(.failure(VoxDemoError.errorWrongUUID()))
                return
        }
        guard let me = self.me
            else {
                completion(.failure(VoxDemoError.errorNotLoggedIn()))
                return
        }
        
        remoteDataSource.sendMessage(with: text, in: viConversation) { result in
            if case .failure (let error) = result { completion(.failure(error)) }
            if case .success (let viEvent) = result {
                completion(.success(self.builder.buildMessageEvent(with: viEvent, and: me)))
            }
        }
    }
    
    func edit(message: Message, with text: String, completion: @escaping MessageEventCompletion) {
        guard let viMessage = remoteDataSource.recreateMessage(with: message.uuid, and: message.conversation)
            else {
                completion(.failure(VoxDemoError.errorWrongUUID()))
                return
        }
        guard let me = self.me
            else {
                completion(.failure(VoxDemoError.errorNotLoggedIn()))
                return
        }
        
        remoteDataSource.edit(message: viMessage, with: text) { result in
            if case .failure (let error) = result { completion(.failure(error)) }
            if case .success (let viEvent) = result {
                completion(.success(self.builder.buildMessageEvent(with: viEvent, and: me)))
            }
        }
    }
    
    // MARK: - Events -
    // MARK: - Service
    func markAsRead(sequence: Int64, in conversation: Conversation) {
        guard let viConversation = remoteDataSource.recreateConversation(with: conversation.uuid,
                                                                         and: self.builder.buildConfig(for: conversation), nil)
            else { return }
        
        remoteDataSource.markAsRead(sequence: sequence, in: viConversation)
    }
    
    func sendTyping(to conversation: Conversation) {
        guard let viConversation = remoteDataSource.recreateConversation(with: conversation.uuid,
                                                                         and: self.builder.buildConfig(for: conversation), nil)
            else { return }
        
        remoteDataSource.sendTyping(in: viConversation)
    }
    
    // MARK: - Retransmit
    func requestMessengerEvents(for conversation: Conversation, completion: @escaping EventArrayCompletion) {
        guard let viConversation = remoteDataSource.recreateConversation(with: conversation.uuid,
                                                                       and: self.builder.buildConfig(for: conversation), conversation.lastSequence) else { fatalError() }
        
        remoteDataSource.requestMessengerEvents(for: viConversation) { result in
            if case .failure (let error) = result { completion(.failure(error)) }
            if case .success (let viEvents) = result {
                
                let conversationUsers = conversation.participants.map { $0.user }
                
                var neededUserIDsForEvents: [NSNumber] = viEvents.compactMap { $0.imUserId }.uniques
                
                viConversation.participants.forEach { participant in
                    neededUserIDsForEvents.removeAll { $0 == participant.imUserId }
                }
                
                if !neededUserIDsForEvents.isEmpty {
                    self.requestUsers(with: neededUserIDsForEvents) { result in
                        if case .failure (let error) = result { completion(.failure(error)) }
                        if case .success (let users) = result {
                            
                            var allNeededUsers = conversationUsers
                            
                            allNeededUsers.append(contentsOf: users)
                            completion(.success(self.process(viEvents: viEvents, with: allNeededUsers)))
                        }
                    }
                }
                else {
                    completion(.success(self.process(viEvents: viEvents, with: conversationUsers)))
                }
            }
        }
    }
    
    private func process(viEvents: [VIMessengerEvent], with users: [User]) -> [MessengerEvent] {
        var events: [MessengerEvent] = []
        var messageEvents: [MessageEvent] = []
        
        viEvents.forEach { viEvent in
            let initiator = users.first { $0.imID == viEvent.imUserId }
            
            if let viMessageEvent = viEvent as? VIMessageEvent
            {
                let messageEvent = self.builder.buildMessageEvent(with: viMessageEvent, and: initiator!)
                messageEvents.append(messageEvent)
            }
            else if let viConversationEvent = viEvent as? VIConversationEvent
            {
                
                let eventModel = self.builder.buildConversationEvent(with: viConversationEvent, users, and: initiator!)
                events.append(.conversation(eventModel))
            }
        }
        
        messageEvents.forEach { event in
            
            if event.action == .remove {
                messageEvents
                    .removeAll() { $0.message.uuid == event.message.uuid }
            }
                
            else if event.action == .edit {
                let eventMentions: [MessageEvent] = messageEvents
                    .filter { $0.message.uuid == event.message.uuid }
                    .sorted { $0.sequence < $1.sequence }
                
                if eventMentions.count > 1 {
                    let last = eventMentions.last!
                    let first = eventMentions.first!
                    
                    let message = Message(uuid: last.message.uuid, text: last.message.text,
                                          conversation: last.message.conversation, sequence: first.message.sequence)
                    
                    let updatedEvent = MessageEvent(initiator: first.initiator, action: last.action,
                                                    message: message, sequence: first.sequence, timestamp: first.timestamp)
                    messageEvents
                        .removeAll { $0.message.uuid == event.message.uuid }
                    messageEvents
                        .append(updatedEvent)
                }
            }
        }
        
        messageEvents.forEach { events.append(MessengerEvent.message($0)) }
        events.sort { $0.sequence < $1.sequence }
        
        return events
    }
    
    
    // MARK: - VoxSDKServiceDelegate -
    func didReceive(conversationEvent: VIConversationEvent) {
        guard let initiatorID = conversationEvent.imUserId else { return }
        
        remoteDataSource.requestUser(with: initiatorID) { result in
            if case .failure = result { return }
            if case .success (let initiator) = result {
                if conversationEvent.action == .removeConversation {
                    self.delegate?.didReceiveConversationEvent(self.builder.buildConversationEvent(with: conversationEvent, [], and: initiator))
                    return
                }
                
                let userIDArray = conversationEvent.conversation.participants.map { $0.imUserId }
                
                self.remoteDataSource.requestUsers(with: userIDArray) { result in
                    if case .failure = result { return }
                    if case .success (let users) = result {
                        self.delegate?.didReceiveConversationEvent(self.builder.buildConversationEvent(with: conversationEvent, users, and: initiator))
                    }
                }
            }
        }
    }
    
    func didReceive(messageEvent: VIMessageEvent) {
        guard let initiatorID = messageEvent.imUserId else { return }
        
        remoteDataSource.requestUser(with: initiatorID) { result in
            if case .failure = result { return }
            if case .success (let initiator) = result {
                self.delegate?.didReceiveMessageEvent(self.builder.buildMessageEvent(with: messageEvent, and: initiator))
            }
        }
    }
    
    func didReceive(serviceEvent: VIConversationServiceEvent) {
        guard let initiatorID = serviceEvent.imUserId else { return }
        
        remoteDataSource.requestUser(with: initiatorID) { result in
            if case .failure = result { return }
            if case .success (let initiator) = result {
                self.delegate?.didReceiveServiceEvent(self.builder.buildServiceEvent(with: serviceEvent, and: initiator))
            }
        }
    }
    
    func didReceive(userEvent: VIUserEvent) {
        self.delegate?.didReceiveUserEvent(self.builder.buildUserEvent(with: userEvent))  
    }
    
}

// MARK: - Extensions -
fileprivate extension Array where Element: Hashable {
    var uniques: Array {
        var buffer = Array()
        var added = Set<Element>()
        for elem in self {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
}

fileprivate extension String {
    var stringWithAccAndAppDomains: String {
        return "\(self)@\(appName).\(accountName)"
    }
}
