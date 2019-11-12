/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ConversationInfoInteractorInput {
    var me: User? { get }
    func viewWillAppear()
    func requestConversation(for model: Conversation)
    func editConversation(_ conversation: Conversation, with title: String,
                          _ description: String?, _ pictureName: String?, isPublic: Bool?)
    func leaveConversation(_ conversation: Conversation)
}

protocol ConversationInfoInteractorOutput: AnyObject, ConnectionEvents {
    func isConversationUUIDEqual(to UUID: String) -> Bool
    func didUpdate(conversation: Conversation)
    func didRemove(conversation: Conversation)
    func didEdit(user: User)
    func didLeaveConversation()
    func readEventReceived(with sequence: Int)
    func failedToRequestConversation(with error: Error)
    func failedToEditConversation(with error: Error)
    func failedToLeaveConversation(with error: Error)
    func messageEventReceived()
}

class ConversationInfoInteractor: ConversationInfoInteractorInput, RepositoryDelegate, AuthServiceDelegate {
    weak var output: ConversationInfoInteractorOutput?
    
    private let authService: AuthServiceProtocol = sharedAuthService
    private let repository: Repository = sharedRepository
    
    required init(output: ConversationInfoInteractorOutput) { self.output = output }
    
    // MARK: - ConversationInfoInteractorInput -
    var me: User? { return repository.me }
    
    func viewWillAppear() {
        repository.set(delegate: self)
        authService.set(delegate: self)
    }
    
    func editConversation(_ conversation: Conversation, with title: String,
                          _ description: String?, _ pictureName: String?, isPublic: Bool?) {
        
        repository.update(conversation: conversation, title: title, description: description,
                                      pictureName: pictureName, isPublic: isPublic)
        { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToEditConversation(with: error) }
            else if case .success = result {
                var updatedConversation = conversation
                updatedConversation.title = title
                updatedConversation.description = description
                updatedConversation.pictureName = pictureName
                if let isPublic = isPublic { updatedConversation.isPublic = isPublic }
                
                self.output?.didUpdate(conversation: updatedConversation) }
        }
    }
    
    func requestConversation(for model: Conversation) {
        repository.requestConversation(with: model.uuid) { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToRequestConversation(with: error) }
            else if case .success (let conversation) = result { self.output?.didUpdate(conversation: conversation) }
        }
    }
    
    func leaveConversation(_ conversation: Conversation) {
        repository.leave(conversation: conversation) { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToLeaveConversation(with: error) }
            else if case .success = result { self.output?.didLeaveConversation() }
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
