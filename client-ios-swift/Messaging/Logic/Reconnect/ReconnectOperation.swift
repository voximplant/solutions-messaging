/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

final class ReconnectOperation: AsyncOperation {
    private let attemptsLimit: Int
    private let sleepTime: UInt32
    private let timeout: TimeInterval
    private let resultCompletion: (Error?) -> Void
    private let login: (@escaping LoginCompletion) -> Void
    private var attempt = 0
    private var timer: Timer?
    
    init(attemptsLimit: Int,
         waitForTheNextAttempt period: Int,
         timeout: Int,
         completion: @escaping (Error?) -> Void,
         login: @escaping (@escaping LoginCompletion) -> Void
    ) {
        self.attemptsLimit = attemptsLimit
        self.sleepTime = UInt32(period)
        self.resultCompletion = completion
        self.login = login
        self.timeout = TimeInterval(timeout)
        super.init()
    }
    
    override func main() {
        super.main()
        
        let timer = Timer(timeInterval: timeout, repeats: false) { _ in
            Log.i("ReconnectOperation timer fired")
            self.cancel()
            self.resultCompletion(ReconnectError.timeout)
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .default)
        attemptToReconnect(completion: resultCompletion)
    }
    
    override func cancel() {
        super.cancel()
        timer?.invalidate()
    }
    
    private func attemptToReconnect(completion: @escaping (Error?) -> Void) {
        if isCancelled { return }
        
        attempt += 1
        
        Log.i("Reconnecting operation, attempt \(attempt)")
        if attempt >= attemptsLimit {
            completion(ReconnectError.timeout)
            state = .done
            return
        }
        login { [weak self] error in
            guard let self = self else { return }
            if self.isCancelled { return }
            
            if let error = error {
                self.handleError(error: error, completion: completion)
            } else {
                completion(nil)
                self.timer?.invalidate()
                self.state = .done
            }
        }
    }
    
    private func handleError(error: Error, completion: @escaping (Error?) -> Void) {
        Log.i("ReconnectOperation is about to handle error \(error)")
        if isCancelled { return }
        if let error = error as NSError? {
            switch error.code {
            case VIConnectivityError.Code.connectivityCheckFailed.rawValue:
                sleep(sleepTime)
                attemptToReconnect(completion: completion)
            case VIConnectivityError.Code.connectionFailed.rawValue:
                sleep(sleepTime)
                attemptToReconnect(completion: completion)
            case VILoginError.Code.networkIssues.rawValue:
                sleep(sleepTime)
                attemptToReconnect(completion: completion)
            case VILoginError.Code.timeout.rawValue:
                attemptToReconnect(completion: completion)
            default:
                completion(ReconnectError.reconnectFailed)
                state = .done
            }
        }
    }
}
