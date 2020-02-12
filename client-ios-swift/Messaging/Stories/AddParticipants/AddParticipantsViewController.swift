/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol AddParticipantsViewInput: AnyObject, UIIndicator {
    var userList: UserListView! { get }
    func updateTitle(with text: String)
    func enableAddButton(_ enable: Bool)
}

protocol AddParticipantsViewOutput: AnyObject, ControllerLifeCycle {
    func addButtonPressed()
}

final class AddParticipantsViewController: ViewController, AddParticipantsViewInput {
    var output: AddParticipantsViewOutput!
        
    @IBOutlet private weak var addButton: UIBarButtonItem!
    @IBOutlet weak var userList: UserListView!
    
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
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        output.addButtonPressed()
    }
    
    // MARK: - AddParticipantsViewInput -
    func enableAddButton(_ enable: Bool) {
        addButton.isEnabled = enable
    }
    
    func updateTitle(with text: String) {
        title = text
    }
}
