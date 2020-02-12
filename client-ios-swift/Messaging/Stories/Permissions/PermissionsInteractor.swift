/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol PermissionsInteractorInput {
    var me: User { get }
    func setupDelegates()
    func editPermissions(_ newPermissions: Permissions, in conversation: Conversation)
}

protocol PermissionsInteractorOutput: AnyObject, ConnectionEvents {
    func didEditPermissions(_ newPermissions: Permissions)
    func failedToEditPermissions(with error: Error)
    func didEdit(conversation: Conversation)
    func didRemove(conversation: Conversation)
    func didEdit(user: User)
    func readEventReceived(with sequence: Int)
    func isConversationUUIDEqual(to UUID: String) -> Bool
    func messageEventReceived()
}

final class PermissionsInteractor: PermissionsInteractorInput, RepositoryDelegate, AuthServiceDelegate {
    weak var output: PermissionsInteractorOutput?
    
    var me: User { return repository.me! }
    
    private let authService: AuthServiceProtocol = sharedAuthService
    private let repository: Repository = sharedRepository
    
    required init(output: PermissionsInteractorOutput) { self.output = output }
    
    func editPermissions(_ newPermissions: Permissions, in conversation: Conversation) {
        var participants: [Participant] = []
        conversation.participants.forEach {
            if !$0.isOwner { participants.append($0) }
        }
        for index in 0 ..< participants.count {
            participants[index].permissions = newPermissions
        }
        
        repository.edit(participants: participants, in: conversation) { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToEditPermissions(with: error) }
            else if case .success (_) = result {
                self.repository.update(conversation: conversation, permissions: newPermissions) { [weak self] result in
                    guard let self = self else { return }
                    if case .failure (let error) = result { self.output?.failedToEditPermissions(with: error) }
                    else if case .success = result { self.output?.didEditPermissions(newPermissions) }
                }
            }
        }
    }
    
    // MARK: - PermissionsInteractorInput
    func setupDelegates() {
        repository.set(delegate: self)
        authService.set(delegate: self)
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
    }
    
    func didFailToLogin(with error: Error) {
        output?.tryingToLogin()
    }
}
