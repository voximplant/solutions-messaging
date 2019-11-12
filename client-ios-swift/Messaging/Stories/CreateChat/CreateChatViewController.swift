/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol CreateChatViewInput: AnyObject, UIIndicator {
    var userListView: UserListView! { get }
    var conversationInfoView: ProfileInfoView! { get }
    func setTitle(_ text: String)
    func userInteraction(allowed: Bool)
}

protocol CreateChatViewOutput: AnyObject, ControllerLifeCycle {
    func createChatPressed()
}

class CreateChatViewController: ViewController, CreateChatViewInput {
    var output: CreateChatViewOutput!
    
    @IBOutlet weak var createButton: UIBarButtonItem!
    @IBOutlet weak var conversationInfoView: ProfileInfoView!
    @IBOutlet weak var userListView: UserListView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        output?.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        output.viewWillAppear()
    }
    
    // MARK: - CreateChatViewInput
    func setTitle(_ text: String) { title = text }
    
    func userInteraction(allowed: Bool) {
        view.isUserInteractionEnabled = allowed
        createButton.isEnabled = allowed
    }
    
    // MARK: - CreateChatViewOutput
    @IBAction func createChatButtonPressed(_ sender: UIBarButtonItem) {
        output?.createChatPressed()
    }
}
