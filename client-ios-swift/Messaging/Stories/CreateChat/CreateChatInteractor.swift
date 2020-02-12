/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol CreateChatInteractorInput: AnyObject {
    var me: User { get }
    func setupDelegates()
    func createChannel(with title: String, imageName: String?, description: String, and userModelArray: [User])
    func createConversation(with title: String, and userModelArray: [User], imageName: String?, description: String, isPublic: Bool, isUber: Bool)
    func requestUsers()
}

protocol CreateChatInteractorOutput: AnyObject, ConnectionEvents {
    func chatCreated(_ model :Conversation)
    func failedToCreateChat(with error: Error)
    func usersLoaded(_ users: [User])
    func usersLoadingFailed(with error: Error)
    func didEdit(user: User)
}

final class CreateChatInteractor: CreateChatInteractorInput, RepositoryDelegate, AuthServiceDelegate {
    weak var output: CreateChatInteractorOutput?
    
    private let authService: AuthServiceProtocol = sharedAuthService
    private let repository: Repository = sharedRepository
    
    var me: User { return repository.me! }
    
    required init(output: CreateChatInteractorOutput) { self.output = output }
    
    // MARK: - CreateDirectInteractorInput
    func setupDelegates() {
        repository.set(delegate: self)
        authService.set(delegate: self)
    }
    
    func requestUsers() {
        repository.requestAllUsers { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.usersLoadingFailed(with: error) }
            if case .success (let userModelArray) = result { self.output?.usersLoaded(userModelArray) }
        }
    }
    
    // MARK: - CreateChatInteractorInput
    func createConversation(with title: String, and userModelArray: [User], imageName: String?, description: String, isPublic: Bool, isUber: Bool) {
        repository.createGroupConversation(with: title, and: userModelArray, description: description,
                                           pictureName: imageName, isPublic: isPublic, isUber: isUber)
        { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToCreateChat(with: error) }
            if case .success (let conversationModel) = result { self.output?.chatCreated(conversationModel) }
        }
    }
    
    func createChannel(with title: String, imageName: String?, description: String, and userModelArray: [User]) {
        repository.createChannel(with: title, and: userModelArray, description: description, pictureName: imageName)
        { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToCreateChat(with: error) }
            if case .success (let conversationModel) = result { self.output?.chatCreated(conversationModel) }
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
