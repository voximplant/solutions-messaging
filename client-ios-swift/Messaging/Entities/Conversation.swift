/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

struct Conversation {
    let uuid: String
    let type: ConversationType
    var title: String
    var participants: [Participant]
    var pictureName: String? // doesnt exist in direct chats
    var description: String? // doesnt exist in direct chats
    var permissions: Permissions? // doesnt exist in direct chats
    var lastUpdated: TimeInterval
    var lastSequence: Int
    let isDirect: Bool
    var isPublic: Bool
    let isUber: Bool
    var latestReadSequence: Int
}
