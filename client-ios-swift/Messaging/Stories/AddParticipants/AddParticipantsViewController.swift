/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol AddParticipantsViewInput: AnyObject, HUDShowable {
    var userListView: UserListView { get }
    var title: String? { get set }
    func allowAdding(_ allow: Bool)
}

protocol AddParticipantsViewOutput: AnyObject, ControllerLifeCycleObserver {
    func addButtonPressed()
}

final class AddParticipantsViewController: UIViewController, AddParticipantsViewInput {
    var output: AddParticipantsViewOutput! // DI
    let userListView: UserListView = UserListView()
    
    @IBOutlet private weak var addButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(userListView)
        userListView.translatesAutoresizingMaskIntoConstraints = false
        userListView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        userListView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        userListView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        userListView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        
        output.viewDidLoad()
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
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        output.addButtonPressed()
    }
    
    // MARK: - AddParticipantsViewInput -
    func allowAdding(_ allow: Bool) {
        addButton.isEnabled = allow
    }
}
