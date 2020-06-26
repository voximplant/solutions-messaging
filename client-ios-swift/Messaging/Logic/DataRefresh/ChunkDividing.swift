/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ChunkDividing: AnyObject {
    var chunkSize: Int { get }
}

extension ChunkDividing {
    func performChunkedOperation<Input, Output>(
        data: [Input],
        chunkCompletion: @escaping (Result<[Output], Error>) -> Void,
        method: @escaping ([Input], @escaping (Result<[Output], Error>) -> Void) -> Void,
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
            
            method(croppedData) { result in
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
