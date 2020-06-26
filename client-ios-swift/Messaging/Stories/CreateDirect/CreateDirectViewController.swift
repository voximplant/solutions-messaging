/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol CreateDirectViewInput: AnyObject, HUDShowable { }

protocol CreateDirectViewOutput: AnyObject, ControllerLifeCycleObserver {
    func openCreateChannel()
    func openCreateChat()
}

final class CreateDirectViewController: UIViewController, CreateDirectViewInput {
    var output: CreateDirectViewOutput! // DI
    let userListView: UserListView = UserListView()
    
    @IBOutlet private weak var buttonsStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(userListView)
        userListView.translatesAutoresizingMaskIntoConstraints = false
        userListView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        userListView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        userListView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        userListView.topAnchor.constraint(equalTo: buttonsStackView.bottomAnchor).isActive = true
        
        output.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        output.viewWillAppear()
    }
    
    @IBAction func newChannelButtonPressed(_ sender: GrayButton) {
        output.openCreateChannel()
    }
    
    @IBAction func newGroupButtonPressed(_ sender: GrayButton) {
        output.openCreateChat()
    }
}
