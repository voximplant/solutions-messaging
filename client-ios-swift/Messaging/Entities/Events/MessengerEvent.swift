/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

enum MessengerEvent {
    case message (MessageEvent)
    case conversation (ConversationEvent)
    case service (ServiceEvent)
    case user (UserEvent)
    
    func either(isMessageEvent: ((MessageEvent) -> Void)? = nil,
                isConversationEvent: ((ConversationEvent) -> Void)? = nil,
                isServiceEvent: ((ServiceEvent) -> Void)? = nil,
                isUserEvent: ((UserEvent) -> Void)? = nil) {
        switch self {
        case let .message(messageEvent):
            isMessageEvent?(messageEvent)
        case let .conversation(conversationEvent):
            isConversationEvent?(conversationEvent)
        case let .service(serviceEvent):
            isServiceEvent?(serviceEvent)
        case let .user(userEvent):
            isUserEvent?(userEvent)
        }
    }
    
    var initiator: User {
        switch self {
        case let .message(messageEvent):
            return messageEvent.initiator
        case let .conversation(conversationEvent):
            return conversationEvent.initiator
        case let .service(serviceEvent):
            return serviceEvent.initiator
        case let .user(userEvent):
            return userEvent.initiator
        }
    }
    
    var sequence: Int {
        switch self {
        case let .message(messageEvent):
            return messageEvent.sequence
        case let .conversation(conversationEvent):
            return conversationEvent.sequence
        case let .service(serviceEvent):
            return serviceEvent.sequence
        case .user :
            return 0
        }
    }
}

