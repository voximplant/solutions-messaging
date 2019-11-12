/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

typealias CustomData = [String: NSObject]

extension CustomData {
    var type: NSString? {
        get { return self["type"] as? NSString }
        set { self["type"] = newValue }
    }
    
    var image: NSString? {
        get { return self["image"] as? NSString }
        set { self["image"] = newValue }
    }
    
    var chatDescription: NSString? {
        get { return self["description"] as? NSString }
        set { self["description"] = newValue }
    }
    
    var status: NSString? {
        get { return self["status"] as? NSString }
        set { self["status"] = newValue }
}
    
    var permissions: NSDictionary? {
        get { return self["permissions"] as? NSDictionary }
        set { self["permissions"] = newValue }
    }
}
