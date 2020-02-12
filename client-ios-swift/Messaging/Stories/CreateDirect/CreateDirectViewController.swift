/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol CreateDirectViewInput: AnyObject, UIIndicator {
    var userListView: UserListView! { get }
}

protocol CreateDirectViewOutput: AnyObject, ControllerLifeCycle {
    func channelButtonPressed()
    func groupChatButtonPressed()
}

final class CreateDirectViewController: ViewController, CreateDirectViewInput {
    var output: CreateDirectViewOutput!
    
    @IBOutlet weak var userListView: UserListView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        output.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        output.viewWillAppear()
    }
    
    @IBAction func newChannelButtonPressed(_ sender: GrayButton) {
        output.channelButtonPressed()
    }
    
    @IBAction func newGroupButtonPressed(_ sender: GrayButton) {
        output.groupChatButtonPressed()
    }
}
