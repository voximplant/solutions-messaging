/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol CreateDirectInteractorInput: AnyObject {
    var numberOfUsers: Int { get }
    func getUser(at indexPath: IndexPath) -> User
    func createDirect(with userID: User.ID)
    func setupObservers(_ observer: DataSourceObserver<User>)
}

protocol CreateDirectInteractorOutput: AnyObject {
    func conversationCreated(_ conversation: Conversation)
    func failedToCreateConversation(with error: Error)
}

final class CreateDirectInteractor: CreateDirectInteractorInput {
    weak var output: CreateDirectInteractorOutput?
    
    private let repository: Repository
    private let userDataSource: UserDataSource
    private var userObserver: DataSourceObserver<User>?
    private let includeMe = false
    
    init(output: CreateDirectInteractorOutput,
         repository: Repository,
         userDataSource: UserDataSource
    ) {
        self.output = output
        self.repository = repository
        self.userDataSource = userDataSource
    }
    
    deinit {
        if let userObserver = userObserver {
            userDataSource.removeObserver(userObserver)
            self.userObserver = nil
        }
    }
    
    // MARK: - CreateDirectInteractorInput
    var numberOfUsers: Int {
        userDataSource.getNumberOfUsers(includingMe: includeMe)
    }
    
    func getUser(at indexPath: IndexPath) -> User {
        userDataSource.getUser(at: indexPath, includingMe: includeMe)
    }
    
    func createDirect(with userID: User.ID) {
        repository.createDirectConversation(with: userID) { [weak self] result in
            if case .success (let conversation) = result {
                self?.output?.conversationCreated(conversation)
            }
            if case .failure (let error) = result {
                self?.output?.failedToCreateConversation(with: error)
            }
        }
    }
    
    func setupObservers(_ observer: DataSourceObserver<User>) {
        userObserver = observer
        userDataSource.observeUsers(includingMe: includeMe, observer: observer)
    }
}
