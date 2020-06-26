/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

typealias CustomData = [String: NSObject]

extension CustomData {
    var type: Conversation.ConversationType {
        get {
            switch self["type"] as? String {
            case "direct":
                return .direct
            case "chat":
                return .chat
            case "channel":
                return .channel
            default:
                return .chat
            }
        }
        set {
            var typeString: NSString?
            switch newValue {
            case .direct:
                typeString = "direct"
            case .chat:
                typeString = "chat"
            case .channel:
                typeString = "channel"
            }
            self["type"] = typeString
        }
    }
    
    var image: String? {
        get { self["image"] as? String }
        set { self["image"] = newValue as NSString? }
    }
    
    var chatDescription: String? {
        get { self["description"] as? String }
        set { self["description"] = newValue as NSString? }
    }
    
    var status: String? {
        get { self["status"] as? String }
        set { self["status"] = newValue as NSString? }
    }
    
    var permissions: NSDictionary? {
        get { self["permissions"] as? NSDictionary }
        set { self["permissions"] = newValue }
    }
}
