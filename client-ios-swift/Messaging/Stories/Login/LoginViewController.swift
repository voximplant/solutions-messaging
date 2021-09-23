/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol LoginViewInput: AnyObject, HUDShowable {
    var usernameInput: String { get }
    var passwordInput: String { get }
    func updateVersionLabel(with text: String)
    func refreshFields(with username: String)
}

protocol LoginViewOutput: AnyObject, ControllerLifeCycleObserver {
    func login()
}

final class LoginViewController:
    UIViewController,
    MovingWithKeyboard,
    LoginViewInput
{
    var output: LoginViewOutput! // DI
    
    @IBOutlet private weak var userField: CustomTextField!
    @IBOutlet private weak var passwordField: CustomTextField!
    @IBOutlet private weak var versionLabel: UILabel!
    
    var usernameInput: String { userField.text?.withAccount.withVoximplantDomain ?? "" }
    var passwordInput: String { passwordField.text ?? "" }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    // MARK: MovingWithKeyboard
    var adjusted: Bool = false
    var defaultValue: CGFloat = 0.0
    var keyboardWillChangeFrameObserver: NSObjectProtocol?
    var keyboardWillHideObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeOnKeyboardEvents()
        navigationController?.isNavigationBarHidden = true
        output.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        output.viewWillAppear()
    }
    
    deinit {
        unsubscribeFromKeyboardEvents()
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        output.login()
    }
        
    // MARK: - LoginViewInput
    func updateVersionLabel(with text: String) {
        versionLabel.text = text
    }
    
    func refreshFields(with username: String) {
        userField.text = username
        passwordField.text = ""
    }
}
