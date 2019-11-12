/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

enum ConversationType {
    case direct
    case chat
    case channel
    
    var customDataValue: NSString {
        switch self {
        case .direct: return "direct"
        case .chat: return "chat"
        case .channel: return "channel"
        }
    }
    
    var defaultPermissions: Permissions {
        switch self {
        case .direct: return Permissions.defaultForDirect()
        case .chat: return Permissions.defaultForChat()
        case .channel: return Permissions.defaultForChannel()
        }
    }
    
    init(customDataValue: NSString?) {
        switch customDataValue {
        case "direct": self = .direct
        case "chat": self = .chat
        case "channel": self = .channel
        default: self = .chat
        }
    }
}
