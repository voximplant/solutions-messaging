/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

enum MessageEventAction {
    case send
    case edit
    case remove
}

final class MessageEvent {
    let initiator: User
    var action: MessageEventAction
    let sequence: Int
    var message: Message
    let timestamp: TimeInterval
    
    init(initiator: User, action: MessageEventAction, message: Message, sequence: Int, timestamp: TimeInterval) {
        self.initiator = initiator
        self.action = action
        self.sequence = sequence
        self.message = message
        self.timestamp = timestamp
    }
}
