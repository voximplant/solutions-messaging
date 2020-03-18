/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class ActiveConversationTableView: TableView {
    override var cellTypes: [UITableViewCell.Type] { [EventTableCell.self, MessageTableCell.self] }
}
