/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol LoginViewInput: AnyObject, UIIndicator {
    var usernameInput: String { get }
    var passwordInput: String? { get }
    func updateVersionLabel(with text: String)
    func refreshFields(with username: String)
}

protocol LoginViewOutput: AnyObject, ControllerLifeCycle {
    func loginButtonPressed()
}

class LoginViewController: ViewController, LoginViewInput {
    var output: LoginViewOutput!
    
    @IBOutlet private weak var userField: CustomTextField!
    @IBOutlet private weak var passwordField: CustomTextField!
    @IBOutlet private weak var versionLabel: UILabel!
    
    var usernameInput: String { return userField.stringWithAccAndAppDomains }
    var passwordInput: String? { return passwordField.text }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        moveViewWithKeyboard()
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        output.viewWillAppear()
    }
    
    override func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height / 3
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    @IBAction func loginButtonPressed(_ sender: Any) { output.loginButtonPressed() }
        
    // MARK: - LoginViewInput
    func updateVersionLabel(with text: String) { versionLabel.text = text }
    func refreshFields(with username: String) {
        userField.text = username
        passwordField.text = ""
    }
    
    deinit { removeKeyboardObservers() }
}

fileprivate extension UITextField {
    var stringWithAccAndAppDomains: String
    { return (text ?? "") + "@\(appName).\(accountName)\(voxDomain)" }
}
