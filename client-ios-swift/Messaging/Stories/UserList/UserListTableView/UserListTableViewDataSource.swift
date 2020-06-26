/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class UserListTableView: TableView {
    override var cellTypes: [UITableViewCell.Type] { [UserListCell.self] }
    
    override weak var delegate: UITableViewDelegate? {
        didSet {
            delegateInterceptor = delegate as? UserListTableViewDelegate
        }
    }
    
    weak var delegateInterceptor: UserListTableViewDelegate?
    
    var allowsEditing: Bool = false
}
