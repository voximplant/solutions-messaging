/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

struct Conversation: Identifiable, Equatable {
    let uuid: String
    let type: ConversationType
    var title: String
    var participants: [Participant]
    var pictureName: String?
    var description: String?
    var permissions: Permissions
    var lastUpdated: TimeInterval
    var lastSequence: Int
    var isPublic: Bool
    let isUber: Bool
    var lastReadSequence: Int
    
    // Identifiable
    var id: String { uuid }
    
    enum ConversationType: Int16 {
        case direct = 0
        case chat = 1
        case channel = 2
    }
}
