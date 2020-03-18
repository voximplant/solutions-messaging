/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

struct MessageTableCellModel: MessengerCellModel {
    let sequence: Int
    let time: String
    var text: String
    var senderName: String
    let isMy: Bool
    var isRead: Bool = false
    var isEdited: Bool = false
    var isFailed: Bool = false
    var dialogOutput: MessageDialogViewOutput?
}

extension MessageTableCellModel {
    init(with event: MessageEvent, myImId: NSNumber, and output: MessageDialogViewOutput?) {
        self.init(
            sequence: event.message.sequence,
            time: buildStringTime(from: event.timestamp),
            text: event.message.text,
            senderName: event.initiator.displayName,
            isMy: event.initiator.imID == myImId,
            isEdited: event.action == .edit,
            dialogOutput: output
        )
    }
}

typealias MessageDialogAction = (_ cell: MessageTableCell, _ sequence: Int) -> Void

struct MessageDialogViewOutput {
    var editAction: MessageDialogAction
    var removeAction: MessageDialogAction
    var cancelAction: MessageDialogAction
}
