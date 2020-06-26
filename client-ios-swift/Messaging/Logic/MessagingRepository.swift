/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

final class MessagingRepository:
    Repository,
    VoximplantEventDelegate,
    DataRefresher,
    ModelBuilder
{
    private let backend: Backend
    private let voximplantService: VoximplantDataSource
    private let dataBase: DataBaseController
    
    private let refreshQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .utility
        queue.name = "refreshQueue"
        return queue
    }()
    
    var typingObserver: ((Participant) -> Void)?
    
    init(backend: Backend,
         voximplantService: VoximplantDataSource,
         dataBase: DataBaseController
    ) {
        self.backend = backend
        self.voximplantService = voximplantService
        self.dataBase = dataBase
        self.voximplantService.delegate = self
    }
    
    // MARK: - DataRefresher -
    func refresh() {
        backend.getVoxUsernames { result in
            if case .success (let usernames) = result {
                self.refreshUsers(usernames.compactMap { $0.withAccount })
            }
            if case .failure (let error) = result {
                Log.e(error.localizedDescription)
            }
        }
    }
    
    func cancelRefresh() {
        refreshQueue.cancelAllOperations()
    }
    
    func refreshUsers(_ usernames: [String]) {
        let refreshOperation = UsersRefreshOperation(
            usernames: usernames,
            getUsersMethod: voximplantService.requestUsers(with:completion:)
        ) { users in
            if let me = users.first(where: { $0.name == self.voximplantService.myUsername }) {
                forEach(data: users.map { ($0, $0 == me)}, method: self.dataBase.saveUser(_:completion:)) { error in
                    if let error = error {
                        Log.e("Error saving users to dataBase \(error.localizedDescription)")
                        return
                    }
                    if let myConversations = me.conversationList,
                        !myConversations.isEmpty {
                        self.refreshConversations(myConversations)
                    } else {
                        Log.w("my conversations are empty or nil, wont retransmit")
                    }
                }
            } else {
                Log.e("me was nil on refreshUsers")
            }
        }
        
        refreshQueue.addOperation(refreshOperation)
    }
    
    func refreshConversations(_ uuids: [String]) {
        let refreshOperation = ConversationsRefreshOperation(
            conversationUUIDs: uuids,
            getConversationsMethod: self.voximplantService.requestConversations(with:completion:),
            chunkCompletion: { chunkResult in
                if case .success (let conversations) = chunkResult {
                    conversations.forEach { conversation in
                        self.dataBase.saveConversation(conversation) { error in
                            if let error = error as NSError? {
                                Log.e("\(error.localizedDescription) \(error.userInfo)")
                                return
                            }
                            self.retransmitEvents(conversation: conversation)
                        }
                    }
                }
                if case .failure (let error) = chunkResult {
                    Log.e(error.localizedDescription)
                }
            }
        )
        
        refreshQueue.addOperation(refreshOperation)
    }
    
    func retransmitEvents(conversation: VIConversation) {
        var startSequence: Int64 = 1
        if let latestStoredSequence = dataBase.eventDataSource.getLatestStoredEventSequence(conversationUUID: conversation.uuid) {
            if latestStoredSequence < 1 || latestStoredSequence >= conversation.lastSequence {
                return
            } else {
                startSequence = latestStoredSequence
            }
        }
        
        let retransmitOperation = RetransmitEventsOperation(
            conversation: conversation,
            since: startSequence,
            retransmitEventsMethod: self.voximplantService.requestMessengerEvents(for:events:completion:),
            chunkCompletion: { chunkResult in
                if case .success (let events) = chunkResult {
                    self.dataBase.process(viEvents: events) { error in
                        if let error = error {
                            self.handleError(error, message: "RetransmitOperation chunk saving error")
                        }
                    }
                }
                if case .failure (let error) = chunkResult {
                    self.handleError(error, message: "RetransmitOperation chunk error")
                }
            }
        )
        
        refreshQueue.addOperation(retransmitOperation)
    }
    
    // MARK: - Users -
    func editUser(
        with profilePictureName: String? = nil,
        and status: String? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        var customData: CustomData = [:]
        if let pictureName = profilePictureName { customData.image = pictureName }
        if let status = status { customData.status = status }

        voximplantService.editUser(with: customData) { result in
            if case .success (let viUser) = result {
                self.dataBase.saveUser(viUser, me: viUser.name == self.voximplantService.myUsername) { error in
                    if let error = error {
                        Log.e("Error during saveUser \(viUser) \(error.localizedDescription)")
                    }
                    completion(error)
                }
            }
            if case .failure (let error) = result { completion(error) }
        }
    }
    
    // MARK: - Conversations -
    // MARK: - Create Conversation
    func createDirectConversation(with userID: User.ID, completion: @escaping ConversationCompletion) {
        guard let me = dataBase.me else {
            completion(.failure(VoxDemoError.notLoggedIn))
            return
        }
        
        let config = VIConversationConfig()
        config.title = ""
        config.isDirect = true
        config.isUber = false
        config.isPublicJoin = false
        config.participants = [buildVIParticipant(with: NSNumber(value: userID), for: .direct),
                               buildVIParticipant(with: NSNumber(value: me.imID), for: .direct)]
        config.customData.type = .direct
        config.customData.permissions = Permissions.defaultPermissions(for: .direct).nsDictionary
        createConversation(with: config, completion)
    }
    
    func createGroupConversation(
        with title: String, and users: Set<User.ID>,
        description: String, pictureName: String?,
        isPublic: Bool, isUber: Bool,
        completion: @escaping ConversationCompletion
    ) {
        let config = VIConversationConfig()
        config.title = title
        config.isDirect = false
        config.isUber = isUber
        config.isPublicJoin = isPublic
        config.participants = users.map {
            buildVIParticipant(with: NSNumber(value: $0), for: .chat)
        }
        config.customData = buildCustomData(for: Conversation.ConversationType.chat, pictureName, and: description)
        createConversation(with: config, completion)
    }
    
    func createChannel(
        with title: String, and users: Set<User.ID>,
        description: String, pictureName: String?,
        completion: @escaping ConversationCompletion)
    {
        let config = VIConversationConfig()
        config.title = title
        config.isDirect = false
        config.isUber = false
        config.isPublicJoin = true
        config.participants = users.map {
            buildVIParticipant(with: NSNumber(value: $0), for: .channel)
        }
        config.customData = buildCustomData(for: Conversation.ConversationType.channel, pictureName, and: description)
        createConversation(with: config, completion)
    }
    
    private func createConversation(
        with config: VIConversationConfig,
        _ completion: @escaping ConversationCompletion
    ) {
        voximplantService.createConversation(with: config) { result in
            if case .success (let viEvent) = result {
                self.dataBase.saveConversation(viEvent.conversation) { error in
                    if let error = error {
                        self.handleError(error, message: "Error during saveConversation after create")
                        completion(.failure(error))
                        return
                    }
                    self.dataBase.processEvent(viEvent) { error in
                        if let error = error {
                            self.handleError(error, message: "Error during processEvent after create")
                            completion(.failure(error))
                            return
                        }
                        if let conversation = self.dataBase.conversationDataSource.getConversation(with: viEvent.conversation.uuid) {
                            completion(.success(conversation))
                        } else {
                            completion(.failure(VoxDemoError.noDataReceived))
                        }
                    }
                }
            }
            if case .failure (let error) = result {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Edit Conversation
    func addUsers(
        to conversation: Conversation,
        users: Set<User.ID>,
        completion: @escaping (Error?) -> Void
    ) {
        guard let viConversation = recreate(from: conversation) else {
            completion(VoxDemoError.wrongUUID)
            return
        }
        
        let viParticipants = users.map {
            VIConversationParticipant(imUserId: NSNumber(value: $0))
        }

        
        self.voximplantService.addParticipants(viParticipants, to: viConversation) { result in
            if case .success (let viEvent) = result {
                self.dataBase.updateConversationParticipants(viEvent.conversation) { error in
                    if let error = error {
                        self.handleError(error, message: "Error during updateConversationParticipants")
                        completion(error)
                        return
                    }
                    self.dataBase.updateConversationLastSequence(
                        conversation.uuid,
                        lastUpdateTime: viEvent.timestamp,
                        lastSequence: viEvent.sequence
                    ) { error in
                        if let error = error {
                            self.handleError(error, message: "Error during updateConversationLastSequence")
                            completion(error)
                            return
                        }
                        self.dataBase.processEvent(viEvent) { error in
                            if let error = error {
                                self.handleError(error, message: "Error during processEvent")
                                completion(error)
                                return
                            }
                            completion(nil)
                        }
                    }
                }
            }
            if case .failure (let error) = result {
                completion(error)
            }
        }
    }
    
    func editParticipants(
        _ participants: [Participant],
        in conversation: Conversation,
        completion: @escaping (Error?) -> Void
    ) {
        guard let viConversation = recreate(from: conversation) else {
            completion(VoxDemoError.wrongUUID)
            return
        }
        
        let viParticipants = participants.map { buildVIParticipant(from: $0) }
        
        voximplantService.editParticipants(viParticipants, in: viConversation) { result in
            if case .success (let viEvent) = result {
                self.dataBase.updateConversationParticipants(viEvent.conversation) { error in
                    if let error = error {
                        self.handleError(error, message: "Error during updateConversationParticipants")
                        completion(error)
                        return
                    }
                    self.dataBase.updateConversationLastSequence(
                        conversation.uuid,
                        lastUpdateTime: viEvent.timestamp,
                        lastSequence: viEvent.sequence
                    ) { error in
                        if let error = error {
                            self.handleError(error, message: "Error during updateConversationLastSequence")
                            completion(error)
                            return
                        }
                        self.dataBase.processEvent(viEvent) { error in
                            if let error = error {
                                self.handleError(error, message: "Error during processEvent")
                                completion(error)
                                return
                            }
                            completion(nil)
                        }
                    }
                }
            }
            if case .failure (let error) = result { completion(error) }
        }
    }
    
    func removeUser(
        from conversation: Conversation,
        _ user: User.ID,
        completion: @escaping (Error?) -> Void
    ) {
        guard let viConversation = recreate(from: conversation) else {
            completion(VoxDemoError.wrongUUID)
            return
        }
        
        let viParticipant = VIConversationParticipant(imUserId: NSNumber(value: user))
        
        voximplantService.removeParticipants([viParticipant], from: viConversation) { result in
            if case .success (let viEvent) = result {
                self.dataBase.updateConversationParticipants(viEvent.conversation) { error in
                    if let error = error {
                        self.handleError(error, message: "Error during updateConversationParticipants")
                        completion(error)
                        return
                    }
                    self.dataBase.updateConversationLastSequence(
                        conversation.uuid,
                        lastUpdateTime: viEvent.timestamp,
                        lastSequence: viEvent.sequence
                    ) { error in
                        if let error = error {
                            self.handleError(error, message: "Error during updateConversationLastSequence")
                            completion(error)
                            return
                        }
                        self.dataBase.processEvent(viEvent) { error in
                            if let error = error {
                                self.handleError(error, message: "Error during processEvent")
                                completion(error)
                                return
                            }
                            completion(nil)
                        }
                    }
                }
            }
            if case .failure (let error) = result {
                completion(error)
            }
        }
    }
    
    func updateConversation(
        _ conversation: Conversation,
        title: String,
        description: String? = nil,
        pictureName: String? = nil,
        isPublic: Bool? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        guard let viConversation = recreate(from: conversation) else {
            completion(VoxDemoError.wrongUUID)
            return
        }
        
        viConversation.title = title
        if let pictureName = pictureName { viConversation.customData.image = pictureName }
        if let description = description { viConversation.customData.chatDescription = description }
        if let isPublic = isPublic { viConversation.isPublicJoin = isPublic }
        
        voximplantService.updateConversation(viConversation) { result in
            if case .success (let viEvent) = result {
                self.dataBase.updateConversation(viEvent.conversation) { error in
                    if let error = error {
                        self.handleError(error, message: "Error during updateConversation")
                        completion(error)
                        return
                    }
                    self.dataBase.updateConversationLastSequence(
                        conversation.uuid,
                        lastUpdateTime: viEvent.timestamp,
                        lastSequence: viEvent.sequence
                    ) { error in
                        if let error = error {
                            self.handleError(error, message: "Error during updateConversationLastSequence")
                            completion(error)
                            return
                        }
                        self.dataBase.processEvent(viEvent) { error in
                            if let error = error {
                                self.handleError(error, message: "Error during processEvent")
                                completion(error)
                                return
                            }
                            completion(nil)
                        }
                    }
                }
            }
            if case .failure (let error) = result { completion(error) }
        }
    }
    
    func updateConversation(
        _ conversation: Conversation,
        permissions: Permissions,
        completion: @escaping (Error?) -> Void
    ) {
        guard let viConversation = recreate(from: conversation) else {
            completion(VoxDemoError.wrongUUID)
            return
        }
        
        var participants = conversation.participants.filter { !$0.isOwner }
        for index in 0 ..< participants.count {
            participants[index].permissions = permissions
        }
        let viParticipants = participants.map { buildVIParticipant(from: $0) }
        
        voximplantService.editParticipants(viParticipants, in: viConversation) { result in
            if case .success (let viEventEdit) = result {
                viConversation.customData.permissions = permissions.nsDictionary
                self.voximplantService.updateConversation(viConversation) { result in
                    if case .success (let viEventUpdate) = result {
                        self.dataBase.updateConversation(
                            viEventUpdate.conversation
                        ) { error in
                            if let error = error {
                                self.handleError(error, message: "Error during updateConversation")
                                completion(error)
                                return
                            }
                            self.dataBase.updateConversationParticipants(
                            viEventUpdate.conversation) { error in
                                if let error = error {
                                    self.handleError(error, message: "Error during updateConversationParticipants")
                                    completion(error)
                                    return
                                }
                                self.dataBase.updateConversationLastSequence(
                                    conversation.uuid,
                                    lastUpdateTime: viEventUpdate.timestamp,
                                    lastSequence: viEventEdit.sequence
                                ) { error in
                                    if let error = error {
                                        self.handleError(error, message: "Error during updateConversationLastSequence")
                                        completion(error)
                                        return
                                    }
                                    self.dataBase.process(
                                        viEvents: [viEventEdit, viEventUpdate]
                                    ) { error in
                                        if let error = error {
                                            self.handleError(error, message: "Error during process events after conversation update")
                                            completion(error)
                                            return
                                        }
                                        completion(nil)
                                    }
                                }
                            }
                        }
                    }
                    if case .failure (let error) = result {
                        completion(error)
                    }
                }
            }
            if case .failure (let error) = result {
                completion(error)
            }
        }
    }
    
    // MARK: - Leave Conversation
    func leaveConversation(_ conversation: Conversation, completion: @escaping (Error?) -> Void) {
        voximplantService.leaveConversation(conversation.uuid) { result in
            if case .success (_) = result {
                self.dataBase.removeConversation(
                    conversation.uuid
                ) { error in
                    if let error = error {
                        self.handleError(error, message: "Error on removingConversation after leave")
                        completion(error)
                        return
                    }
                    completion(nil)
                }
            }
            if case .failure (let error) = result { completion(error) }
        }
    }
    
    // MARK: - Messages -
    func sendMessage(with text: String,
                     conversation: Conversation,
                     completion: @escaping (Error?) -> Void
    ) {
        guard let viConversation = recreate(from: conversation)
            else {
                completion(VoxDemoError.wrongUUID)
                return
        }
        voximplantService.sendMessage(text: text, to: viConversation) { result in
            if case .success (let viEvent) = result {
                self.dataBase.updateConversationLastSequence(
                    conversation.uuid,
                    lastUpdateTime: viEvent.timestamp,
                    lastSequence: viEvent.sequence
                ) { error in
                    if let error = error {
                        self.handleError(error, message: "Error on updating conversationLastSequence after send message")
                        completion(error)
                        return
                    }
                    self.dataBase.processEvent(viEvent) { error in
                        if let error = error {
                            self.handleError(error, message: "Error on processingEvent after sendMessage")
                            completion(error)
                            return
                        }
                        completion(nil)
                    }
                }
            }
            if case .failure (let error) = result { completion(error) }
        }
    }
    
    func editMessage(with uuid: String,
                     conversation: Conversation.ID,
                     text: String,
                     completion: @escaping (Error?) -> Void
    ) {
        guard let viMessage = voximplantService.recreateMessage(uuid, conversation: conversation)
            else {
                completion(VoxDemoError.wrongUUID)
                return
        }
        voximplantService.editMessage(viMessage, with: text) { result in
            if case .success (let viEvent) = result {
                self.dataBase.updateConversationLastSequence(
                    conversation,
                    lastUpdateTime: viEvent.timestamp,
                    lastSequence: viEvent.sequence
                ) { error in
                    if let error = error {
                        self.handleError(error, message: "Error on updating conversationLastSequence after edit message")
                        completion(error)
                        return
                    }
                    self.dataBase.processEvent(viEvent) { error in
                        if let error = error {
                            self.handleError(error, message: "Error on processingEvent after editMessage")
                            completion(error)
                            return
                        }
                        completion(nil)
                    }
                }
            }
            if case .failure (let error) = result { completion(error) }
        }
    }
    
    func removeMessage(with uuid: String,
                       conversation: Conversation.ID,
                       completion: @escaping (Error?) -> Void
    ) {
        guard let viMessage = voximplantService.recreateMessage(uuid, conversation: conversation)
            else {
                completion(VoxDemoError.wrongUUID)
                return
        }
        voximplantService.removeMessage(viMessage) { result in
            if case .success (let viEvent) = result {
                self.dataBase.updateConversationLastSequence(
                    conversation,
                    lastUpdateTime: viEvent.timestamp,
                    lastSequence: viEvent.sequence
                ) { error in
                    if let error = error {
                        self.handleError(error, message: "Error on updating conversationLastSequence after remove message")
                        completion(error)
                        return
                    }
                    self.dataBase.processEvent(viEvent) { error in
                        if let error = error {
                            self.handleError(error, message: "Error on processingEvent after removeMessage")
                            completion(error)
                            return
                        }
                        completion(nil)
                    }
                }
            }
            if case .failure (let error) = result { completion(error) }
        }
    }
    
    // MARK: - ServiceEvents -
    func markAsRead(sequence: Int64, conversation: Conversation) {
        guard let viConversation = recreate(from: conversation) else {
                return
        }
        voximplantService.markAsRead(sequence: sequence, in: viConversation) { error in
            if let error = error {
                Log.e("Failed to mark \(sequence) as read with error \(error.localizedDescription)")
                return
            }
            guard let myID = self.dataBase.me?.imID else {
                Log.e("Failed to update lastRead \(sequence) in dataBase becase myID is nil")
                return
            }
            self.dataBase.updateLastReadSequence(
                participantID: ParticipantObject.ID(
                    userID: User.ID(truncating: NSNumber(value: myID)),
                    conversationID: conversation.uuid
                ),
                sequence: sequence
            ) { error in
                if let error = error {
                    self.handleError(error, message: "Failed to update lastRead \(sequence)")
                    return
                }
                Log.i("Successfully marked \(sequence) as read on serviceEvent")
            }
        }
    }
    
    func sendTyping(to conversation: Conversation) {
        guard let viConversation = recreate(from: conversation) else {
            Log.w("Recreate failed for \(conversation)")
            return
        }
        voximplantService.sendTyping(in: viConversation)
    }
    
    // MARK: - VoxSDKServiceDelegate -
    func didReceive(conversationEvent: VIConversationEvent) {
        let saveEvent: () -> Void = {
            self.dataBase.updateConversationLastSequence(
                conversationEvent.conversation.uuid,
                lastUpdateTime: conversationEvent.timestamp,
                lastSequence: conversationEvent.sequence
            ) { error in
                if let error = error {
                    self.handleError(error, message: "There was an error during updateConversationLastSequence")
                    return
                }
                self.dataBase.processEvent(conversationEvent) { error in
                    if let error = error {
                        self.handleError(error, message: "There was an error saving conversationEvent \(conversationEvent)")
                    }
                }
            }
        }
        
        switch conversationEvent.action {
        case .createConversation:
            self.dataBase.saveConversation(
                conversationEvent.conversation
            ) { error in
                if let error = error {
                    self.handleError(error, message: "Did receive conversationEvent(create) but could'nt save its conversation")
                    return
                }
                saveEvent()
            }
        case .removeConversation:
            self.dataBase.removeConversation(
                conversationEvent.conversation.uuid
            ) { error in
                if let error = error {
                    self.handleError(error, message: "Did receive conversationEvent(remove) but could'nt remove its conversation")
                    return
                }
            }
        case .editConversation:
            guard let myId = self.dataBase.me?.imID else {
                Log.e("Did receive conversation event, but me was null. skipping")
                return
            }
            
            if !conversationEvent.conversation.participants.contains(where: { $0.imUserId.int64Value == myId }) {
                self.dataBase.removeConversation(
                    conversationEvent.conversation.uuid
                ) { error in
                    if let error = error {
                        self.handleError(error, message: "Has been kicked(or left) conversation but could'nt remove it")
                        return
                    }
                    Log.i("Did receive conversation event, but my participant was null. conversation deleted")
                }
                return
            }
            
            self.dataBase.updateConversation(
                conversationEvent.conversation
            ) { error in
                if let error = error {
                    self.handleError(error, message: "Did receive conversationEvent(update) but could'nt update its conversation")
                    return
                }
                saveEvent()
            }
        case .addParticipants, .removeParticipants, .joinConversation, .leaveConversation, .editParticipants:
            guard let myId = self.dataBase.me?.imID else {
                Log.e("Did receive conversation event, but me was null. skipping")
                return
            }
            
            if !conversationEvent.conversation.participants.contains(where: { $0.imUserId.int64Value == myId }) {
                self.dataBase.removeConversation(
                    conversationEvent.conversation.uuid
                ) { error in
                    if let error = error {
                        self.handleError(error, message: "Has been kicked(or left) conversation but could'nt remove it")
                        return
                    }
                    Log.i("Did receive conversation event, but my participant was null. conversation deleted")
                }
                return
            }
            
            if dataBase.conversationDataSource.getConversation(with: conversationEvent.conversation.uuid) == nil {
                self.dataBase.saveConversation(conversationEvent.conversation) { error in
                    if let error = error {
                        self.handleError(error, message: "Error during saveConversation")
                        return
                    }
                    Log.i("Did receive conversation event, but conversation was null. retransmitting..")
                    self.retransmitEvents(conversation: conversationEvent.conversation)
                }
                return
            }
            
            self.dataBase.updateConversationParticipants(
                conversationEvent.conversation
            ) { error in
                if let error = error {
                    self.handleError(error, message: "Did receive conversationEvent(upd participants) but could'nt update its participants")
                    return
                }
                saveEvent()
            }
        default:
            Log.w("Did receive conversationEvent \(conversationEvent) with \(conversationEvent.action) that was not handled")
        }
    }
    
    func didReceive(messageEvent: VIMessageEvent) {
        dataBase.updateConversationLastSequence(
            messageEvent.message.conversation,
            lastUpdateTime: messageEvent.timestamp,
            lastSequence: messageEvent.sequence
        ) { error in
            if let error = error {
                self.handleError(error, message: "Failed to updateConversationLastSequence")
                return
            }
            self.dataBase.processEvent(messageEvent) { error in
                if let error = error {
                    self.handleError(error, message: "There was an error saving messageEvent \(messageEvent)")
                }
            }
        }
    }
    
    func didReceive(serviceEvent: VIConversationServiceEvent) {
        guard let userID = serviceEvent.imUserId else {
            return
        }
        if serviceEvent.action == .isRead {
            self.dataBase.updateLastReadSequence(
                participantID: ParticipantObject.ID(
                    userID: userID.int64Value,
                    conversationID: serviceEvent.conversationUUID
                ),
                sequence: serviceEvent.sequence
            ) { error in
                if let error = error {
                    self.handleError(error, message: "Failed to updateLastReadSequence \(serviceEvent.sequence) in dataBase")
                    return
                }
                self.dataBase.updateEventsReadMark(
                    conversation: serviceEvent.conversationUUID,
                    sequence: serviceEvent.sequence
                ) { error in
                    if let error = error {
                        self.handleError(error, message: "Failed to updateEventsReadMark \(serviceEvent.sequence) in dataBase")
                        return
                    }
                    Log.i("Successfully marked \(serviceEvent.sequence) as read on serviceEvent")
                }
            }
        }
        if serviceEvent.action == .typing,
            let participant = dataBase.getParticipant(
                id: ParticipantObject.ID(
                    userID: userID.int64Value,
                    conversationID: serviceEvent.conversationUUID
                )
            ) {
            Log.i("About to notify typing observer")
            typingObserver?(participant)
        }
    }
    
    func didReceive(userEvent: VIUserEvent) {
        dataBase.updateUser(userEvent.user) { error in
            if let error = error {
                Log.e("Failed to update user with error \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Recreate -
    private func recreate(from conversation: Conversation) -> VIConversation? {
        voximplantService.recreateConversation(with: conversation.uuid, and: buildConfig(for: conversation))
    }
    
    private func recreate(from event: MessageEvent) -> VIMessage? {
        voximplantService.recreateMessage(event.message.uuid, conversation: event.conversation.uuid)
    }
    
    // MARK: - Utils -
    private func handleError(_ error: Error, message: String = "") {
        if let error = error as NSError? {
            Log.e("\(message) \(error.localizedDescription) \(error.userInfo)")
        } else if let error = error as? CoreDataError {
            Log.e("\(message) \(error.localizedDescription)")
        } else {
            Log.e("\(message) \(error.localizedDescription)")
        }
    }
}
