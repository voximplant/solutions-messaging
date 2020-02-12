/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol SettingsViewInput: AnyObject, UIIndicator {
    var profileHeaderView: ProfileInfoView! { get }
    func allowEditing(_ allow: Bool)
    func setupHeaderViewAppearance(with model: UserProfileModel)
}

protocol SettingsViewOutput: AnyObject, ControllerLifeCycle {
    func logoutPressed()
    func editButtonPressed()
    func saveButtonPressed()
}

final class SettingsViewController: ViewController, SettingsViewInput {
    var output: SettingsViewOutput!
    
    @IBOutlet weak var profileHeaderView: ProfileInfoView!
    @IBOutlet weak var rightBarButton: BarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        output.viewDidLoad()
        rightBarButton.buttonAction = .edit
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        output.viewWillAppear()
    }
    
    @IBAction func logoutButtonPressed(_ sender: Any) {
        output?.logoutPressed()
    }

    @IBAction func barButtonPressed(_ sender: BarButtonItem) {
        if sender.buttonAction == .edit { output.editButtonPressed() }
        else if sender.buttonAction == .save { output.saveButtonPressed() }
    }
    
    // MARK: - SettingsViewInput
    func allowEditing(_ allow: Bool) {
        profileHeaderView.isEditable = allow
        rightBarButton.buttonAction = allow ? .save : .edit
    }
    
    func setupHeaderViewAppearance(with model: UserProfileModel) {
        profileHeaderView.type = .user(model: model)
    }
    
}
