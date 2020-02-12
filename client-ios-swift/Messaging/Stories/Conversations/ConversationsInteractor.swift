/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ConversationsInteractorInput: AnyObject {
    func loginWithAccessToken()
    func fetchConversations()
    func setupDelegates()
    var me: User? { get }
}

protocol ConversationsInteractorOutput: AnyObject, ConnectionEvents {
    func didCreate(conversation: Conversation)
    func didUpdate(conversation: Conversation)
    func didRemove(conversation: Conversation)
    func beenRemoved(from conversation: Conversation)
    func didReceive(conversations: [Conversation])
    func didReceive(messageEvent: MessageEvent)
    func fetchingFailed(with error: Error)
}

final class ConversationsInteractor: ConversationsInteractorInput, RepositoryDelegate, AuthServiceDelegate {
    weak var output: ConversationsInteractorOutput?
    
    private let authService: AuthServiceProtocol = sharedAuthService
    private let repository: Repository = sharedRepository
    
    var me: User? { return repository.me }
    
    required init(output: ConversationsInteractorOutput) { self.output = output }
    
    // MARK: - ConversationsInteractorInput -
    func setupDelegates() {
        repository.set(delegate: self)
        authService.set(delegate: self)
    }
    
    func loginWithAccessToken() {
        output?.tryingToLogin()
        authService.loginWithAccessToken { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.loginFailed(with: error) }
            else if case .success (_) = result { self.output?.loginCompleted() }
        }
    }
    
    func fetchConversations() {
        repository.requestMyConversations { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.fetchingFailed(with: error) }
            else if case .success (let conversationModelArray) = result {
                self.output?.didReceive(conversations: conversationModelArray)
            }
        }
    }
    
    // MARK: - MessagingRepositoryDelegate -
    func didReceiveMessageEvent(_ event: MessageEvent) {
        guard let output = output else { return }
        switch event.action {
        case .send   : output.didReceive(messageEvent: event)
        case .edit   : break
        case .remove : break
        }
    }
    
    func didReceiveConversationEvent(_ event: ConversationEvent) {
        guard let output = output else { return }
        switch event.action {
        case .createConversation : output.didCreate(conversation: event.conversation)
        case .editConversation   : output.didUpdate(conversation: event.conversation)
        case .removeConversation : output.didRemove(conversation: event.conversation)
        case .addParticipants    : output.didUpdate(conversation: event.conversation)
        case .editParticipants   : output.didUpdate(conversation: event.conversation)
        case .removeParticipants : output.beenRemoved(from: event.conversation)
        case .joinConversation   : output.didUpdate(conversation: event.conversation)
        case .leaveConversation  : output.didUpdate(conversation: event.conversation)
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
        output?.loginFailed(with: error)
    }
}
