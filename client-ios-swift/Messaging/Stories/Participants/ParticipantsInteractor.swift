/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ParticipantsInteractorInput: AnyObject {
    var me: User { get }
    func viewWillAppear()
    func requestConversation(for model: Conversation)
    func remove(member: User, conversation: Conversation)
    func remove(admin: User, conversation: Conversation)
}

protocol ParticipantsInteractorOutput: AnyObject, ConnectionEvents {
    func didRemove(participant: User)
    func failedToRemove(participant: User, _ error: Error)
    func didRemove(admin: User)
    func failedToRemove(admin: User, with error: Error)
    func isConversationUUIDEqual(to UUID: String) -> Bool
    func failedToRequestConversation(with error: Error)
    func didUpdate(conversation: Conversation)
    func didRemove(conversation: Conversation)
    func didEdit(user: User)
    func readEventReceived(with sequence: Int)
    func messageEventReceived()
}

class ParticipantsInteractor: ParticipantsInteractorInput, RepositoryDelegate, AuthServiceDelegate {
    weak var output: ParticipantsInteractorOutput?
    
    var me: User { return repository.me! }
    
    private let authService: AuthServiceProtocol = sharedAuthService
    private let repository: Repository = sharedRepository
    
    init(output: ParticipantsInteractorOutput) { self.output = output }
    
    // MARK: - ParticipantsInteractorInput -
    func viewWillAppear() {
        repository.set(delegate: self)
        authService.set(delegate: self)
    }
    
    func remove(member: User, conversation: Conversation) {
        repository.remove(participant: member, from: conversation) { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToRemove(participant: member, error) }
            else if case .success = result { self.output?.didRemove(participant: member) }
        }
    }
    
    func remove(admin: User, conversation: Conversation) {
        if var participant = conversation.participants.first(where: { $0.user.imID == admin.imID }),
            let permissions = conversation.permissions {
            participant.isOwner = false
            participant.permissions = permissions
            
            repository.edit(participants: [participant], in: conversation) { [weak self] result in
                guard let self = self else { return }
                if case .failure (let error) = result { self.output?.failedToRemove(admin: admin, with: error) }
                else if case .success (_) = result { self.output?.didRemove(admin: admin) }
            }
        }
    }
    
    func requestConversation(for model: Conversation) {
        repository.requestConversation(with: model.uuid) { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToRequestConversation(with: error) }
            else if case .success (let conversation) = result { self.output?.didUpdate(conversation: conversation) }
        }
    }
    
    // MARK: - MessagingRepositoryDelegate -
    func didReceiveMessageEvent(_ event: MessageEvent) {
        guard let output = output else { return }
        if !output.isConversationUUIDEqual(to: event.message.conversation) { return }
        output.messageEventReceived()
    }
    
    func didReceiveConversationEvent(_ event: ConversationEvent) {
        guard let output = output else { return }
        if !output.isConversationUUIDEqual(to: event.conversation.uuid) { return }
        switch event.action {
        case .editConversation   : output.didUpdate(conversation: event.conversation)
        case .addParticipants    : output.didUpdate(conversation: event.conversation)
        case .removeParticipants : output.didUpdate(conversation: event.conversation)
        case .joinConversation   : output.didUpdate(conversation: event.conversation)
        case .leaveConversation  : output.didUpdate(conversation: event.conversation)
        case .removeConversation : output.didRemove(conversation: event.conversation)
        case .editParticipants   : output.didUpdate(conversation: event.conversation)
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
    
    // MARK: - AuthServiceDelegate -
    func didDisconnect() {
        output?.connectionLost()
    }
    
    func reconnecting() {
        output?.tryingToLogin()
    }
    
    func didLogin(with displayName: String) {
        output?.loginCompleted()
    }
    
    func didFailToLogin(with error: Error) {
        output?.tryingToLogin()
    }
}
