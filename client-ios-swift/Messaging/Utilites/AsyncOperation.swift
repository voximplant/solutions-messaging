/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

class AsyncOperation: Operation {
    override var isConcurrent: Bool { true }
    override var isAsynchronous: Bool { true }
    override var isFinished: Bool { state == .done }
    override var isExecuting: Bool { state == .started }
    
    var state: State = .initial {
        willSet {
            // due to a legacy issue, these have to be strings. Don't make them key paths.
            willChangeValue(forKey: "isExecuting")
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            Log.i("\(String(describing: Self.self)) state changed \(state)")
            didChangeValue(forKey: "isFinished")
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    override func main() {
        super.main()
        if isCancelled { return }
        state = .started
    }
    
    override func cancel() {
        super.cancel()
        state = .done
    }
    
    enum State {
        case initial
        case started
        case done
    }
}
