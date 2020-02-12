/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

final class MessageCellModel {
    let sequence: Int
    let time: String
    var text: String
    var senderName: String
    let isMy: Bool
    var isRead: Bool
    var isEdited: Bool
    var isFailed: Bool
    
    init(sequence: Int, time: String, text: String, senderName: String, isMy: Bool, isRead: Bool = false, isEdited: Bool = false, isFailed: Bool = false) {
        self.sequence = sequence
        self.time = time
        self.text = text
        self.senderName = senderName
        self.isMy = isMy
        self.isRead = isRead
        self.isEdited = isEdited
        self.isFailed = isFailed
    }
}

final class EventCellModel {
    let sequence: Int
    let initiatorName: String
    let text: String
    
    init(sequence: Int, initiatorName: String, text: String) {
        self.sequence = sequence
        self.initiatorName = initiatorName
        self.text = text
    }
}

enum MessengerCellModel {
    case message (MessageCellModel)
    case event (EventCellModel)
    
    func either(isMessage: ((MessageCellModel) -> Void)? = nil, isEvent: ((EventCellModel) -> Void)? = nil) {
        switch self {
        case let .message(messageModel):
            isMessage?(messageModel)
        case let .event(eventModel):
            isEvent?(eventModel)
        }
    }
    
    var sequence: Int {
        switch self {
        case let .message(messageModel): return messageModel.sequence
        case let .event(eventModel): return eventModel.sequence
        }
    }
    
    var isMessage: Bool {
        switch self {
        case .message: return true
        case .event: return false
        }
    }
}
