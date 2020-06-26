/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol SettingsInteractorInput: AnyObject {
    var me: User? { get }
    func logout()
    func editUser(with pictureName: String?, and status: String?)
    func setupObservers(_ observer: DataSourceObserver<User>)
    func removeObservers()
}

protocol SettingsInteractorOutput: AnyObject {
    func logoutCompleted()
    func failedToEditUser(with error: Error)
    func userEditSuccess()
}

final class SettingsInteractor: SettingsInteractorInput {
    private weak var output: SettingsInteractorOutput?
    private let authService: AuthService
    private let repository: Repository
    private let userDataSource: UserDataSource
    private var dataBaseCleaner: Cleanable
    
    private var userObserver: DataSourceObserver<User>?
    
    var me: User? { userDataSource.me }
    
    init(output: SettingsInteractorOutput,
         authService: AuthService,
         repository: Repository,
         userDataSource: UserDataSource,
         dataBaseCleaner: Cleanable
    ) {
        self.output = output
        self.authService = authService
        self.userDataSource = userDataSource
        self.dataBaseCleaner = dataBaseCleaner
        self.repository = repository
    }
    
    // MARK: - ConversationsInteractorInput
    func setupObservers(_ observer: DataSourceObserver<User>) {
        self.userObserver = observer
        userDataSource.observeUsers(includingMe: true, observer: observer)
    }
    
    func removeObservers() {
        if let observer = userObserver {
            userDataSource.removeObserver(observer)
        }
    }
    
    func logout() {
        authService.logout { [weak self] in
            self?.dataBaseCleaner.clean { [weak self] error in
                if let error = error {
                    Log.e(error.localizedDescription)
                }
                self?.output?.logoutCompleted()
            }
        }
    }
    
    func editUser(with pictureName: String?, and status: String?) {
        repository.editUser(with: pictureName, and: status) { [weak self] error in
            if let error = error {
                self?.output?.failedToEditUser(with: error)
            } else {
                self?.output?.userEditSuccess()
            }
        }
    }
}
