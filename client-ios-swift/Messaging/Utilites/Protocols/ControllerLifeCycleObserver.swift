/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

protocol ControllerLifeCycleObserver {
    func viewDidLoad()
    func viewWillAppear()
    func viewDidAppear()
    func viewWillDisappear()
}

extension ControllerLifeCycleObserver {
    func viewDidLoad() { }
    func viewWillAppear() { }
    func viewDidAppear() { }
    func viewWillDisappear() { }
}
