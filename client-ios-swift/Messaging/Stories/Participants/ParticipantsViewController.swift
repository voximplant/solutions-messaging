/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol ParticipantsViewInput: AnyObject, HUDShowable {
    var userListView: UserListView { get }
    func updateAppearance(with text: String)
}

protocol ParticipantsViewOutput: AnyObject, ControllerLifeCycleObserver {
    func addMember()
}

final class ParticipantsViewController: UIViewController, ParticipantsViewInput {
    var output: ParticipantsViewOutput! // DI
    let userListView: UserListView = UserListView()
    
    @IBOutlet private weak var addButtonContainer: UIView!
    @IBOutlet private weak var addButton: GrayButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(userListView)
        userListView.translatesAutoresizingMaskIntoConstraints = false
        userListView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        userListView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        userListView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        userListView.topAnchor.constraint(equalTo: addButtonContainer.bottomAnchor).isActive = true
        
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
    
    @IBAction func addMemberButtonPressed(_ sender: GrayButton) {
        output.addMember()
    }
    
    // MARK: - ParticipantsViewInput -
    func updateAppearance(with text: String) {
        addButton.setTitle("Add \(text)", for: .normal)
        title = text
    }
}
