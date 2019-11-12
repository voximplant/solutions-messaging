/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

enum UserEventAction {
    case editUser
}

class UserEvent {
    let initiator: User
    let action: UserEventAction
    
    init(initator: User, action: UserEventAction) {
        self.initiator = initator
        self.action = action
    }
}
