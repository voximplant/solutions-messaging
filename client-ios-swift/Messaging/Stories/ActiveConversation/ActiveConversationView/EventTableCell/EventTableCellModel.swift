/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

struct EventTableCellModel: MessengerCellModel {
    let sequence: Int
    let text: String
}

extension EventTableCellModel {
    init(with event: ConversationEvent) {
        let initiatorName = event.initiator.displayName
        var text = ""
        
        switch event.action {
        case .addParticipants   : text = "\(initiatorName) added participants"
        case .removeParticipants: text = "\(initiatorName) removed participants"
        case .editParticipants  : text = "\(initiatorName) edited participants"
        case .editConversation  : text = "\(initiatorName) edited conversation"
        case .createConversation: text = "\(initiatorName) created conversation"
        case .joinConversation  : text = "\(initiatorName) joined conversation"
        case .leaveConversation : text = "\(initiatorName) left conversation"
        case .removeConversation: text = "\(initiatorName) removed conversation"
        }
        
        self.init(sequence: event.sequence, text: text)
    }
}
