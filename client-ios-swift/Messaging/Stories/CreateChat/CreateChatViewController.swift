/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol CreateChatViewInput: AnyObject, HUDShowable {
    var conversationInfoView: ProfileInfoView! { get }
    var title: String? { get set }
    func allowInteraction(_ allow: Bool)
}

protocol CreateChatViewOutput: AnyObject, ControllerLifeCycleObserver {
    func createChat()
}

final class CreateChatViewController: UIViewController, CreateChatViewInput {
    var output: CreateChatViewOutput! // DI
    let userListView: UserListView = UserListView()
    
    @IBOutlet private weak var createButton: UIBarButtonItem!
    @IBOutlet weak var conversationInfoView: ProfileInfoView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(userListView)
        userListView.translatesAutoresizingMaskIntoConstraints = false
        userListView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        userListView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        userListView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        userListView.topAnchor.constraint(equalTo: conversationInfoView.bottomAnchor).isActive = true
        
        hideKeyboardWhenTappedAround()
        output?.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        output.viewWillAppear()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        output.viewDidAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        output.viewWillDisappear()
    }
    
    // MARK: - CreateChatViewInput
    func allowInteraction(_ allow: Bool) {
        view.isUserInteractionEnabled = allow
        createButton.isEnabled = allow
    }
    
    // MARK: - CreateChatViewOutput
    @IBAction func createChatButtonPressed(_ sender: UIBarButtonItem) {
        output?.createChat()
    }
}
