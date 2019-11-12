/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

class Presenter: ControllerLifeCycle, ConnectionEvents {
    func viewDidLoad() { }
    func viewWillAppear() { }
    func viewDidAppear() { }
    func tryingToLogin() { }
    func loginCompleted() { }
    func connectionLost() { }
    func loginFailed(with error: Error) { }
}

protocol ControllerLifeCycle {
    func viewDidLoad()
    func viewWillAppear()
    func viewDidAppear()
}

protocol ConnectionEvents {
    func tryingToLogin()
    func loginCompleted()
    func connectionLost()
    func loginFailed(with error: Error)
}
