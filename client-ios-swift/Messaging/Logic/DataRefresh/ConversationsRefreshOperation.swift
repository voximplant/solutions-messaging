/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

final class ConversationsRefreshOperation: AsyncOperation, ChunkDividing {
    var chunkSize: Int { 5 }
    
    let uuids: [String]
    let chunkCompletion: VIConversationArrayCompletion
    let method: ([String], @escaping VIConversationArrayCompletion) -> Void
    
    required init(
        conversationUUIDs: [String],
        getConversationsMethod: @escaping ([String], @escaping VIConversationArrayCompletion) -> Void,
        chunkCompletion: @escaping VIConversationArrayCompletion
    ) {
        self.uuids = conversationUUIDs
        self.method = getConversationsMethod
        self.chunkCompletion = chunkCompletion
    }
    
    override func main() {
        super.main()
        
        performChunkedOperation(
            data: uuids,
            chunkCompletion: { [weak self] result in
                if self?.isCancelled ?? true { return }
                self?.chunkCompletion(result)
            },
            method: method
        ) { [weak self] in
            self?.state = .done
        }
    }
}
