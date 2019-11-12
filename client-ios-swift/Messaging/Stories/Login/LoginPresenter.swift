/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

class LoginPresenter: Presenter, LoginViewOutput, LoginInteractorOutput {
    weak var view: LoginViewInput!
    
    var interactor: LoginInteractorInput!
    var router: LoginRouterInput!
    
    private var currentVersion: (vox: String, webrtc: String) { return interactor.getSDKVersion() }
    private var savedUsername: String? { return interactor.getUsername() }
    
    required init(view: LoginViewInput) { self.view = view }
    
    // MARK: - LoginViewOutput
    override func viewWillAppear() {
        view.updateVersionLabel(with: buildVersionFieldText(from: currentVersion))
        view.refreshFields(with: buildUsernameFieldText(from: savedUsername))
        interactor.setupDelegate()
    }
    
    func loginButtonPressed() {
        view.showHUD(with: "Logging in...")
        if let password = view.passwordInput { interactor.login(with: view.usernameInput, and: password) }
        else { view.showError(with: "You must enter password to log in") }
    }
    
    // MARK: - LoginInteractorOutput
    override func loginFailed(with error: Error) {
        view.hideHUD()
        view.showError(with: error.localizedDescription)
    }
    
    override func loginCompleted() {
        view.hideHUD()
        router.showConversationsStory()
    }
    
    // MARK: - Private methods
    private func buildVersionFieldText(from versions: (vox: String, webrtc: String)) -> String {
        return "VoximplantSDK \(versions.vox)\nWebRTC \(versions.webrtc)"
    }
    
    private func buildUsernameFieldText(from username: String?) -> String {
        guard let user = username else { return "" }
        return user.replacingOccurrences(of: "@\(appName).\(accountName)\(voxDomain)", with: "")
    }
}
