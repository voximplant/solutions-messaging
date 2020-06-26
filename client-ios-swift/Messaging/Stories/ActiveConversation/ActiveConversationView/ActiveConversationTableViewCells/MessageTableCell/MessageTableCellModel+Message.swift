/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

extension MessageTableCellModel {
    init(with event: MessageEvent,
         and output: MessageTableCellOutput?,
         permissions: (edit: Bool, remove: Bool)
    ) {
        self.init(
            uuid: event.message.uuid,
            sequence: event.sequence,
            name: event.initiator.displayName,
            time: event.timestamp.timeString,
            text: event.message.removed ? "Deleted" : event.message.text,
            isMy: event.initiator.me,
            editingAllowed: permissions.edit,
            removingAllowed: permissions.remove,
            messageState: event.message.removed
                ? .removed
                : event.message.edited ? .edited : .normal,
            output: output)
    }
}
