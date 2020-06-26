/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

struct MessageEvent: MessengerEvent {
    let initiator: User
    let conversation: Conversation
    let sequence: Int
    var message: Message
    let timestamp: TimeInterval
}

struct Message {
    let sequence: Int
    let uuid: String
    let text: String
    var edited: Bool = false
    var removed: Bool = false
    var isRead: Bool = false
}
