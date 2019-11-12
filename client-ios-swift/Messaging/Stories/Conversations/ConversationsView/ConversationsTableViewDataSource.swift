/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

fileprivate let conversationsCellID = "ConversationsTableViewCell"
fileprivate let conversationsNibName = "ConversationsTableViewCell"

class ConversationsTableView: TableView {
    override var cellID: String { return conversationsCellID }
    override var nibName: String { return conversationsNibName }
}

extension TableViewDataSource where Model == ConversationCellModel {
    static func make(for modelArray: [ConversationCellModel], reuseIdentifier: String = conversationsCellID) -> TableViewDataSource {
        return TableViewDataSource(models: modelArray, reuseIdentifier: reuseIdentifier) { (model, cell) in
            if let cell = cell as? ConversationsTableViewCell { cell.model = model }
        }
    }
}
