/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol AddParticipantsInteractorInput: AnyObject {
    var me: User? { get }
    func setupDelegates()
    func requestUsers()
    func addUsers(_ users: [User], to conversation: Conversation)
    func addAdmins(_ users: [User], in conversation: Conversation) 
}

protocol AddParticipantsInteractorOutput: AnyObject, ConnectionEvents {
    func failedToLoadUsers(with error: Error)
    func didLoadUsers(_ users: [User])
    func failedToAddUsers(with error: Error)
    func didAddUsers(to conversation: Conversation)
    func didAddAdmins(_ adminArray: [User])
    func isConversationUUIDEqual(to UUID: String) -> Bool
    func failedToAddAdmins(with error: Error)
    func didReceiveConversation(with model: Conversation)
    func failedToRequestConversation(with error: Error)
    func didEdit(conversation: Conversation)
    func didRemove(conversation: Conversation)
    func didEdit(user: User)
    func readEventReceived(with sequence: Int)
    func messageEventReceived()
}

class AddParticipantsInteractor: AddParticipantsInteractorInput, RepositoryDelegate, AuthServiceDelegate {
    weak var output: AddParticipantsInteractorOutput?
    
    private let authService: AuthServiceProtocol = sharedAuthService
    private let repository: Repository = sharedRepository
    
    var me: User? { return repository.me }
    
    init(output: AddParticipantsInteractorOutput) { self.output = output }
    
    // MARK: - AddParticipantsInteractorInput
    func setupDelegates() {
        repository.set(delegate: self)
        authService.set(delegate: self)
    }
    
    func requestUsers() {
        repository.requestAllUsers { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToLoadUsers(with: error) }
            if case .success (let userModelArray) = result { self.output?.didLoadUsers(userModelArray) }
        }
    }
    
    func addUsers(_ users: [User], to conversation: Conversation) {
        repository.add(participants: users, to: conversation) { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToAddUsers(with: error) }
            else if case .success (let conversation) = result { self.output?.didAddUsers(to: conversation) }
        }
    }
    
    func addAdmins(_ users: [User], in conversation: Conversation) {
        var participants: [Participant] = []
        for user in users {
            if var participant = conversation.participants.first(where: { $0.user.imID == user.imID }) {
                participant.isOwner = true
                participant.permissions = Permissions.defaultForAdmin()
                participants.append(participant)
            }
        }
        repository.edit(participants: participants, in: conversation) { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToAddAdmins(with: error) }
            else if case .success = result { self.output?.didAddAdmins(users)}
        }
    }
    
    func reloadConversation(with UUID: String) {
        repository.requestConversation(with: UUID) { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToRequestConversation(with: error) }
            else if case .success (let conversation) = result { self.output?.didReceiveConversation(with: conversation) }
        }
    }
    
    // MARK: - MessagingRepositoryDelegate
    func didReceiveMessageEvent(_ event: MessageEvent) {
        guard let output = output else { return }
        if !output.isConversationUUIDEqual(to: event.message.conversation) { return }
        output.messageEventReceived()
    }
    
    func didReceiveConversationEvent(_ event: ConversationEvent) {
        guard let output = output else { return }
        if !output.isConversationUUIDEqual(to: event.conversation.uuid) { return }
        switch event.action {
        case .editConversation   : output.didEdit(conversation: event.conversation)
        case .addParticipants    : output.didEdit(conversation: event.conversation)
        case .removeParticipants : output.didEdit(conversation: event.conversation)
        case .joinConversation   : output.didEdit(conversation: event.conversation)
        case .leaveConversation  : output.didEdit(conversation: event.conversation)
        case .removeConversation : output.didRemove(conversation: event.conversation)
        case .editParticipants   : output.didEdit(conversation: event.conversation)
        case .createConversation : break
        }
    }
    
    func didReceiveUserEvent(_ event: UserEvent) {
        guard let output = output else { return }
        switch event.action {
        case .editUser : output.didEdit(user: event.initiator)
        }
    }
    
    func didReceiveServiceEvent(_ event: ServiceEvent) {
         guard let output = output else { return }
         if !output.isConversationUUIDEqual(to: event.conversationUUID) { return }
         switch event.action {
         case .typing : break
         case .read   : output.readEventReceived(with: event.sequence)
         }
     }
    
    // MARK: - AuthServiceDelegate
    func didDisconnect() {
        output?.connectionLost()
    }
    
    func reconnecting() {
        output?.tryingToLogin()
    }
    
    func didLogin(with displayName: String) {
        output?.loginCompleted()
        requestUsers()
    }
    
    func didFailToLogin(with error: Error) {
        output?.tryingToLogin()
    }
}
