/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

final class UsersRefreshOperation: AsyncOperation, ChunkDividing {
    var chunkSize: Int { 20 }
    let usernames: [String]
    let method: ([String], @escaping VIUserArrayCompletion) -> Void
    let completion: ([VIUser]) -> Void
    private var receivedUsers: [VIUser] = []
    private let lock = NSLock()
    
    required init(
        usernames: [String],
        getUsersMethod: @escaping ([String], @escaping VIUserArrayCompletion) -> Void,
        completion: @escaping ([VIUser]) -> Void
    ) {
        self.usernames = usernames
        self.method = getUsersMethod
        self.completion = completion
    }
    
    override func main() {
        super.main()
        
        let chunkCompletion: VIUserArrayCompletion = { [weak self] result in
            if self?.isCancelled ?? true { return }
            
            if case .success (let users) = result {
                if let self = self {
                    self.lock.lock()
                    self.receivedUsers.append(contentsOf: users)
                    self.lock.unlock()
                }
            }
            if case .failure (let error) = result {
                Log.e(error.localizedDescription)
            }
        }
        
        performChunkedOperation(
            data: usernames,
            chunkCompletion: chunkCompletion,
            method: method
        ) { [weak self] in
            if self?.isCancelled ?? true { return }
            self?.completion(self?.receivedUsers ?? [])
            self?.state = .done
        }
    }
}
