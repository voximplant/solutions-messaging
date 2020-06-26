/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol MainQueuePerformable { }

extension MainQueuePerformable {
    func onMainQueue(_ code: @escaping () -> Void) {
        if !Thread.current.isMainThread {
            DispatchQueue.main.async {
                code()
            }
        } else {
            code()
        }
    }
}
