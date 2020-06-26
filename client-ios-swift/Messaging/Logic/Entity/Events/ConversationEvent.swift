/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

struct ConversationEvent: MessengerEvent {
    let initiator: User
    let conversation: Conversation
    let sequence: Int
    let action: ConversationEventAction
    
    enum ConversationEventAction: Int16 {
        case addParticipants = 0
        case editParticipants = 1
        case removeParticipants = 2
        case editConversation = 3
        case joinConversation = 4
        case leaveConversation = 5
        case createConversation = 6
        case removeConversation = 7
    }
}
