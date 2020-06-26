/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol ConversationInfoViewInput: AnyObject, HUDShowable {
    var userListView: UserListView { get }
    var profileHeader: ProfileInfoView! { get }
    var state: ConversationInfoViewControllerState { get set }
    func showLeaveButton(_ show: Bool)
}

protocol ConversationInfoViewOutput: AnyObject, ControllerLifeCycleObserver {
    func rightBarButtonPressed(with sender: BarButtonItem)
    func leaveButtonPressed()
    func addMembersButtonPressed()
    func administratorsButtonPressed()
    func permissionsButtonPressed()
    func membersButtonPressed()
}

enum ConversationInfoViewControllerState {
    case editing (showPermissions: Bool)
    case normal (editingAllowed: Bool, numberOfMembers: Int, showMembers: Bool)
}

final class ConversationInfoViewController: UIViewController, ConversationInfoViewInput {
    var output: ConversationInfoViewOutput! // DI
    let userListView: UserListView = UserListView()
    
    @IBOutlet private weak var rightBarButton: BarButtonItem!
    @IBOutlet private weak var memberLabel: UILabel!
    @IBOutlet private(set) weak var profileHeader: ProfileInfoView!
    @IBOutlet private weak var settingsStackView: UIStackView!
    @IBOutlet private weak var addMembersView: UIView!
    @IBOutlet private var permissionsView: UIView!
    @IBOutlet private weak var leaveButton: UIButton!
    
    var state: ConversationInfoViewControllerState = .normal(editingAllowed: false,
                                                             numberOfMembers: 0,
                                                             showMembers: false) {
        didSet {
            switch state {
            case .editing (let showPermissions):
                settingsStackView.isHidden = false
                addMembersView.isHidden = true
                userListView.isHidden = true
                memberLabel.isHidden = true
                permissionsView.isHidden = !showPermissions
                rightBarButton.buttonAction = .save
                profileHeader.setState(.editing)
                break
            case .normal(let editingAllowed, let numberOfMembers, let showMembers):
                settingsStackView.isHidden = true
                addMembersView.isHidden = !showMembers
                userListView.isHidden = !showMembers
                memberLabel.isHidden = !showMembers
                memberLabel.text = numberOfMembers == 1
                    ? "\(numberOfMembers) member"
                    : "\(numberOfMembers) members"
                rightBarButton.buttonAction = editingAllowed ? .edit : .none
                profileHeader.setState(.normal)
                break
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(userListView)
        userListView.translatesAutoresizingMaskIntoConstraints = false
        userListView.bottomAnchor.constraint(equalTo: leaveButton.topAnchor).isActive = true
        userListView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        userListView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        userListView.topAnchor.constraint(equalTo: addMembersView.bottomAnchor).isActive = true
        
        profileHeader.uberContainer.removeFromSuperview()
        
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
    
    @IBAction func rightBarButtonPressed(_ sender: BarButtonItem) {
        output.rightBarButtonPressed(with: sender)
    }
    
    @IBAction func addMembersButtonPressed(_ sender: GrayButton) {
        output.addMembersButtonPressed()
    }
    
    @IBAction func administratorsButtonPressed(_ sender: GrayButton) {
        output.administratorsButtonPressed()
    }
    
    @IBAction func permissionsButtonPressed(_ sender: GrayButton) {
        output.permissionsButtonPressed()
    }
    
    @IBAction func membersButtonPressed(_ sender: GrayButton) {
        output.membersButtonPressed()
    }
    
    @IBAction func leaveButtonPressed(_ sender: UIButton) {
        output.leaveButtonPressed()
    }
    
    // MARK: - ConversationInfoViewInput -
    func showLeaveButton(_ show: Bool) {
        leaveButton.isHidden = !show
    }
}
