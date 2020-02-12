/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

enum ServiceEventAction {
    case read
    case typing
}

final class ServiceEvent {
    let initiator: User
    let action: ServiceEventAction
    let sequence: Int
    let conversationUUID: String
    
    init(initiator: User, action: ServiceEventAction, conversationUUID: String, sequence: Int) {
        self.initiator = initiator
        self.action = action
        self.sequence = sequence
        self.conversationUUID = conversationUUID
    }
}
