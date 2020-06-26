/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

final class RetransmitEventsOperation: AsyncOperation, ChunkDividing {
    var chunkSize: Int { 100 }
    
    let conversation: VIConversation
    let startSequence: Int64
    let chunkCompletion: VIEventArrayCompletion
    let method: (VIConversation, [Int64], @escaping VIEventArrayCompletion) -> Void
    
    required init(
        conversation: VIConversation,
        since sequence: Int64,
        retransmitEventsMethod: @escaping (VIConversation, [Int64], @escaping VIEventArrayCompletion) -> Void,
        chunkCompletion: @escaping VIEventArrayCompletion
    ) {
        self.conversation = conversation
        self.startSequence = sequence
        self.chunkCompletion = chunkCompletion
        self.method = retransmitEventsMethod
    }
    
    override func main() {
        super.main()
        performChunkedOperation(
            data: Array(startSequence...conversation.lastSequence),
            receiver: conversation,
            chunkCompletion: chunkCompletion,
            method: method
        ) { [weak self] in
            self?.state = .done
        }
    }
}

extension ChunkDividing where Self: RetransmitEventsOperation {
    func performChunkedOperation<Receiver, Input, Output>(
        data: [Input],
        receiver: Receiver,
        chunkCompletion: @escaping (Result<[Output], Error>) -> Void,
        method: @escaping (Receiver, [Input], @escaping (Result<[Output], Error>) -> Void) -> Void,
        completion: (() -> Void)? = nil
    ) {
        let lock = NSLock()
        
        let withRemainder = data.count % chunkSize > 0
        let numberOfIterations = withRemainder
            ? data.count / chunkSize + 1
            : data.count / chunkSize
        
        var iterationsCompleted = 0
        
        (0...numberOfIterations - 1).forEach { iteration in
            let min = iteration * chunkSize
            var max = min + (chunkSize - 1)
            while max >= data.count { max -= 1 }
            
            let croppedData = Array(data[min...max])
            
            method(receiver, croppedData) { result in
                chunkCompletion(result)
                
                lock.lock()
                iterationsCompleted += 1
                lock.unlock()
                
                if numberOfIterations == iterationsCompleted {
                    completion?()
                }
            }
        }
    }
}
