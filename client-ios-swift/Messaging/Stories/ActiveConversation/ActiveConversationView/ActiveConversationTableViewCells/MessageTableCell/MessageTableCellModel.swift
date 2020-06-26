/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

struct MessageTableCellModel: MessengerCellModel {
    let uuid: String
    let sequence: Int
    let name: String
    let time: String
    let text: String
    let isMy: Bool
    let isRead: Bool = false
    let editingAllowed: Bool
    let removingAllowed: Bool
    let messageState: MessageState
    
    var output: MessageTableCellOutput?
    
    struct MessageTableCellOutput {
        typealias MessageTableCellAction = (_ cell: MessageTableCell, _ model: MessageTableCellModel) -> Void
        
        var editMessage: MessageTableCellAction
        var removeMessage: MessageTableCellAction
        var closeOptions: MessageTableCellAction
    }
    
    enum MessageState {
        case removed
        case edited
        case normal
    }
}
