/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

enum ConversationEventAction {
    case addParticipants
    case editParticipants
    case removeParticipants
    case editConversation
    case joinConversation
    case leaveConversation
    case createConversation
    case removeConversation
}

final class ConversationEvent {
    let initiator: User
    let action: ConversationEventAction
    let sequence: Int
    let conversation: Conversation
    let timestamp: TimeInterval
    
    init(initiator: User, action: ConversationEventAction, conversation: Conversation, sequence: Int, timestamp: TimeInterval) {
        self.initiator = initiator
        self.action = action
        self.sequence = sequence
        self.conversation = conversation
        self.timestamp = timestamp
    }
}
