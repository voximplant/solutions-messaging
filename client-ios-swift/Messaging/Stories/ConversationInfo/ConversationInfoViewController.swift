/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol ConversationInfoViewInput: AnyObject, UIIndicator {
    var userListView: UserListView! { get }
    var profileHeader: ProfileInfoView! { get }
    func showPermissions(_ allow: Bool)
    func toggleEditView()
    func showEditButton(_ show: Bool)
    func showUserList(_ show: Bool)
    func showLeaveButton(_ show: Bool)
    func changeNumberOfMembers(with number: Int)
}

protocol ConversationInfoViewOutput: AnyObject, ControllerLifeCycle {
    func rightBarButtonPressed(with sender: BarButtonItem)
    func leaveButtonPressed()
    func addMembersButtonPressed()
    func administratorsButtonPressed()
    func permissionsButtonPressed()
    func membersButtonPressed()
    func didAppearAfterAdding(with conversation: Conversation)
    func didAppearAfterRemoving(with conversation: Conversation)
    func didAppearAfterChangingPermissions(_ conversation: Conversation)
}

class ConversationInfoViewController: ViewController, ConversationInfoViewInput {
    var output: ConversationInfoViewOutput!
    
    @IBOutlet weak var rightBarButton: BarButtonItem!
    @IBOutlet weak var memberLabel: UILabel!
    @IBOutlet weak var userListView: UserListView!
    @IBOutlet weak var profileHeader: ProfileInfoView!
    @IBOutlet weak var settingsStackView: UIStackView!
    @IBOutlet weak var addMembersView: UIView!
    @IBOutlet weak var permissionsView: UIView!
    @IBOutlet weak var leaveButton: UIButton!
    
    @IBAction func rightBarButtonPressed(_ sender: BarButtonItem) {
        output.rightBarButtonPressed(with: sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        output.viewDidLoad()
        profileHeader.uberContainer.removeFromSuperview()
        hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        output.viewWillAppear()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        output.viewDidAppear()
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
    func showUserList(_ show: Bool) {
        addMembersView.isHidden = !show
        userListView.isHidden = !show
        memberLabel.isHidden = !show
    }
    
    func showPermissions(_ show: Bool) {
        show
            ? settingsStackView.addArrangedSubview(permissionsView)
            : permissionsView.removeFromSuperview()
    }
    
    func toggleEditView() {
        settingsStackView.isHidden.toggle()
        addMembersView.isHidden.toggle()
        userListView.isHidden.toggle()
        memberLabel.isHidden.toggle()
        rightBarButton.buttonAction = profileHeader.isEditable ? .edit : .save
        profileHeader.isEditable.toggle()
    }
    
    func setEditButtonTitle(_ text: String) {
        rightBarButton.title = text
    }
    
    func showEditButton(_ show: Bool) {
        rightBarButton.buttonAction = show ? .edit : .none
    }
    
    func showLeaveButton(_ show: Bool) {
        leaveButton.isHidden = !show
    }
    
    func changeNumberOfMembers(with number: Int) {
        memberLabel.text = number == 1 ? "\(number) member" : "\(number) members"
    }
}
