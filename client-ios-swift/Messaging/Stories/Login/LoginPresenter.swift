/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

final class LoginPresenter:
    ControllerLifeCycleObserver,
    LoginViewOutput,
    LoginInteractorOutput
{
    private weak var view: LoginViewInput! // DI
    var interactor: LoginInteractorInput! // DI
    var router: LoginRouterInput! // DI
    
    init(view: LoginViewInput) { self.view = view }
    
    // MARK: - LoginViewOutput
    func viewWillAppear() {
        view.updateVersionLabel(with: buildVersionFieldText(from: interactor.sdkVersion))
        view.refreshFields(with: buildUsernameFieldText(from: interactor.username))
    }
    
    func login() {
        view.showHUD(with: "Logging in...")
        interactor.login(with: view.usernameInput, and: view.passwordInput)
    }
    
    // MARK: - LoginInteractorOutput
    func loginFailed(with error: Error) {
        view.hideHUD()
        view.showError(error)
    }
    
    func loginCompleted() {
        view.hideHUD()
        router.showConversationsStory()
    }
    
    // MARK: - Private
    private func buildVersionFieldText(from versions: (vox: String, webrtc: String)) -> String {
        "VoximplantSDK \(versions.vox)\nWebRTC \(versions.webrtc)"
    }
    
    private func buildUsernameFieldText(from username: String?) -> String {
        username?.replacingOccurrences(
            of: "@\(VoximplantConfig.appName).\(VoximplantConfig.accountName)\(VoximplantConfig.voxDomain)",
            with: ""
        ) ?? ""
    }
}
