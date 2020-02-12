/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol CreateDirectInteractorInput: AnyObject {
    var me: User { get }
    func setupDelegates()
    func requestUsers()
    func createDirect(with user: User)
}

protocol CreateDirectInteractorOutput: AnyObject, ConnectionEvents {
    func conversationCreated(conversation model: Conversation)
    func failedToCreateConversation(with error: Error)
    func usersLoaded(_ users: [User])
    func usersLoadingFailed(with error: String)
    func didEdit(user: User)
}

final class CreateDirectInteractor: CreateDirectInteractorInput, RepositoryDelegate, AuthServiceDelegate {    
    weak var output: CreateDirectInteractorOutput?
    
    private let authService: AuthServiceProtocol = sharedAuthService
    private let repository: Repository = sharedRepository
    
    var me: User { return repository.me! }
    
    required init(output: CreateDirectInteractorOutput) { self.output = output }
    
    // MARK: - CreateDirectInteractorInput
    func setupDelegates() {
        repository.set(delegate: self)
        authService.set(delegate: self)
    }
    
    func requestUsers() {
        repository.requestAllUsers { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.usersLoadingFailed(with: error.localizedDescription) }
            if case .success (let userModelArray) = result { self.output?.usersLoaded(userModelArray) }
        }
    }
    
    func createDirect(with user: User) {
        repository.createDirectConversation(with: user) { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToCreateConversation(with: error) }
            if case .success (let conversation) = result { self.output?.conversationCreated(conversation: conversation) }
        }
    }
    
    // MARK: - MessagingRepositoryDelegate
    func didReceiveUserEvent(_ event: UserEvent) {
        guard let output = output else { return }
        switch event.action {
        case .editUser: output.didEdit(user: event.initiator)
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
