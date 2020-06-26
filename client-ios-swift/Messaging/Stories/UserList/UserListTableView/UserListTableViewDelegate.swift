/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol UserListTableViewDelegate: UITableViewDelegate {
    func didDeleteUser(at indexPath: IndexPath)
}
