/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol LoginInteractorInput: AnyObject {
    var sdkVersion: (String, String) { get }
    var username: String? { get }
    
    func login(with user: String, and password: String)
}

protocol LoginInteractorOutput: AnyObject {
    func loginFailed(with error: Error)
    func loginCompleted()
}

final class LoginInteractor: LoginInteractorInput {
    private weak var output: LoginInteractorOutput?
    private let authService: AuthService
    private let dataRefresher: DataRefresher
    
    var sdkVersion: (String, String) { authService.sdkVersion }
    var username: String? { authService.loggedInUser }
    
    init(output: LoginInteractorOutput,
         dataRefresher: DataRefresher,
         authService: AuthService
    ) {
        self.output = output
        self.dataRefresher = dataRefresher
        self.authService = authService
    }
    
    // MARK: - LoginInteractorInput -
    func login(with user: String, and password: String) {
        authService.login(user: user, password: password) { [weak self] error in
            if let error = error {
                self?.output?.loginFailed(with: error)
            } else {
                self?.dataRefresher.refresh()
                self?.output?.loginCompleted()
            }
        }
    }
}
