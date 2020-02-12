/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

fileprivate let messageCellID = "MessageTableViewCell"
fileprivate let messageNibName = "MessageTableViewCell"

final class ActiveConversationTableView: TableView {
    override var cellID: String { return messageCellID }
    override var nibName: String { return messageNibName }
}

extension TableViewDataSource where Model == MessengerCellModel {
    static func make(for modelArray: [MessengerCellModel], reuseIdentifier: String = messageCellID, delegate: MessageTableViewCellDelegate) -> TableViewDataSource {
        return TableViewDataSource(models: modelArray, reuseIdentifier: reuseIdentifier) { (model, cell) in
            if let cell = cell as? MessageTableViewCell {
                cell.model = model
                cell.delegate = delegate
            }
        }
    }
}
