/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol ParticipantsViewInput: AnyObject, UIIndicator {
    var userListView: UserListView! { get }
    func updateAppearance(with text: String)
}

protocol ParticipantsViewOutput: AnyObject, ControllerLifeCycle {
    func addMemberButtonPressed()
    func didAppearAfterAdding(with conversation: Conversation)
}

final class ParticipantsViewController: ViewController, ParticipantsViewInput {
    var output: ParticipantsViewOutput!
    
    @IBOutlet weak var userListView: UserListView!
    @IBOutlet weak var addButton: GrayButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    @IBAction func addMemberButtonPressed(_ sender: GrayButton) {
        output.addMemberButtonPressed()
    }
    
    // MARK: - ParticipantsViewInput -
    func updateAppearance(with text: String) {
        addButton.setTitle("Add \(text)", for: .normal)
        title = text
    }
}
