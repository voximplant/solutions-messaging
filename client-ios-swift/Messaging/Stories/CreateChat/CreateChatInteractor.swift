/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol CreateChatInteractorInput: AnyObject {
    var numberOfUsers: Int { get }
    func getUser(at indexPath: IndexPath) -> User
    func createChannel(title: String, users: Set<User.ID>,
                       imageName: String?, description: String)
    func createConversation(title: String, users: Set<User.ID>,
                            imageName: String?, description: String,
                            isPublic: Bool, isUber: Bool)
    func setupObservers(_ observer: DataSourceObserver<User>)
}

protocol CreateChatInteractorOutput: AnyObject {
    func chatCreated(_ model: Conversation)
    func failedToCreateChat(with error: Error)
}

final class CreateChatInteractor: CreateChatInteractorInput {
    private weak var output: CreateChatInteractorOutput?
    private let repository: Repository
    private let userDataSource: UserDataSource
    private var userObserver: DataSourceObserver<User>?
    
    var numberOfUsers: Int { userDataSource.getNumberOfUsers(includingMe: false) }
    
    init(output: CreateChatInteractorOutput,
         repository: Repository,
         userDataSource: UserDataSource
    ) {
        self.output = output
        self.repository = repository
        self.userDataSource = userDataSource
    }
    
    deinit {
        removeObservers()
    }
    
    // MARK: - CreateDirectInteractorInput
    func getUser(at indexPath: IndexPath) -> User {
        userDataSource.getUser(at: indexPath, includingMe: false)
    }
    
    func setupObservers(_ observer: DataSourceObserver<User>) {
        userObserver = observer
        userDataSource.observeUsers(includingMe: false, observer: observer)
    }
    
    func removeObservers() {
        if let observer = userObserver {
            userDataSource.removeObserver(observer)
            userObserver = nil
        }
    }
    
    // MARK: - CreateChatInteractorInput
    func createConversation(
        title: String,
        users: Set<User.ID>,
        imageName: String?,
        description: String,
        isPublic: Bool,
        isUber: Bool
    ) {
        repository.createGroupConversation(
            with: title,
            and: users,
            description: description,
            pictureName: imageName,
            isPublic: isPublic,
            isUber: isUber
        ) { [weak self] result in
            if case .success (let conversation) = result {
                self?.output?.chatCreated(conversation)
            }
            if case .failure (let error) = result {
                self?.output?.failedToCreateChat(with: error)
            }
        }
    }
    
    func createChannel(
        title: String,
        users: Set<User.ID>,
        imageName: String?,
        description: String
    ) {
        repository.createChannel(
            with: title,
            and: users,
            description: description,
            pictureName: imageName
        ) { [weak self] result in
            if case .success (let conversation) = result {
                self?.output?.chatCreated(conversation)
            }
            if case .failure (let error) = result {
                self?.output?.failedToCreateChat(with: error)
            }
        }
    }
}
