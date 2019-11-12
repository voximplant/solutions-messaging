/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol LoginInteractorInput: AnyObject {
    func setupDelegate()
    func login(with user: String, and password: String)
    func getSDKVersion() -> (String, String)
    func getUsername() -> String?
}

protocol LoginInteractorOutput: AnyObject, ConnectionEvents {
    func loginFailed(with error: Error)
    func loginCompleted()
}

class LoginInteractor: LoginInteractorInput, AuthServiceDelegate {
    weak var output: LoginInteractorOutput?
    
    private let authService: AuthServiceProtocol = sharedAuthService
    
    required init(output: LoginInteractorOutput) { self.output = output }
    
    // MARK: - LoginInteractorInput
    func setupDelegate() {
        authService.set(delegate: self)
    }
    
    func login(with user: String, and password: String) {
        authService.login(user: user, password: password) { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.loginFailed(with: error) }
            else if case .success (_) = result { self.output?.loginCompleted() }
        }
    }
    
    func getSDKVersion() -> (String, String) { return authService.sdkVersion }
    
    func getUsername() -> String? { return authService.loggedInUser }
    
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
        output?.loginFailed(with: error)
    }
}
