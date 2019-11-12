/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol SettingsInteractorInput: AnyObject {
    func setupDelegates()
    var me: User { get }
    func logout()
    func editUser(with pictureName: String?, and status: String?)
}

protocol SettingsInteractorOutput: AnyObject, ConnectionEvents {
    func logoutCompleted()
    func failedToEditUser(with error: Error)
    func userEditSuccess()
}

class SettingsInteractor: SettingsInteractorInput, RepositoryDelegate, AuthServiceDelegate {
    weak var output: SettingsInteractorOutput?
    
    private let authService: AuthServiceProtocol = sharedAuthService
    private let repository: Repository = sharedRepository
    
    var me: User { return repository.me! } // TODO: - remove force unwrap before releas
    
    required init(output: SettingsInteractorOutput) { self.output = output }
    
    // MARK: - ConversationsInteractorInput
    func setupDelegates() {
        repository.set(delegate: self)
        authService.set(delegate: self)
    }
    
    func logout() {
        authService.logout {
            self.repository.removeMe()
            self.output?.logoutCompleted()
        }
    }
    
    func editUser(with pictureName: String?, and status: String?) {
        repository.editUser(with: pictureName, and: status) { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToEditUser(with: error) }
            else if case .success (_) = result { self.output?.userEditSuccess() }
        }
    }
    
    // MARK: - MessagingRepositoryDelegate

    
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
