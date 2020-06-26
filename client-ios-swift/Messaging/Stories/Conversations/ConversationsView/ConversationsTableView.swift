/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class ConversationsTableView: TableView {
    override var cellTypes: [UITableViewCell.Type] { [ConversationTableCell.self] }
}
