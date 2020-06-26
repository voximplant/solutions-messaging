/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol SettingsViewInput: AnyObject, HUDShowable {
    var profileHeaderView: ProfileInfoView! { get }
    func allowEditing(_ allow: Bool)
}

protocol SettingsViewOutput: AnyObject, ControllerLifeCycleObserver {
    func logout()
    func editButtonPressed()
    func saveButtonPressed()
}

final class SettingsViewController: UIViewController, SettingsViewInput {
    var output: SettingsViewOutput! // DI
    
    @IBOutlet weak var profileHeaderView: ProfileInfoView!
    @IBOutlet private weak var rightBarButton: BarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rightBarButton.buttonAction = .edit
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
    
    @IBAction func logoutButtonPressed(_ sender: Any) {
        output?.logout()
    }

    @IBAction func barButtonPressed(_ sender: BarButtonItem) {
        if sender.buttonAction == .edit { output.editButtonPressed() }
        else if sender.buttonAction == .save { output.saveButtonPressed() }
    }
    
    // MARK: - SettingsViewInput
    func allowEditing(_ allow: Bool) {
        rightBarButton.buttonAction = allow ? .save : .edit
        profileHeaderView.setState(allow ? .editing : .normal)
    }
}
