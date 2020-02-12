/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

fileprivate let userListCellID = "UserListCell"
fileprivate let userListNibName = "UserListCell"

final class UserListTableView: TableView {
    override var cellID: String { return userListCellID }
    override var nibName: String { return userListNibName }
    
    override weak var delegate: UITableViewDelegate? {
        didSet {
            delegateInterceptor = delegate as? UserListTableViewDelegate
        }
    }
    
    weak var delegateInterceptor: UserListTableViewDelegate?
    
    var allowsEditing: Bool = false
}

final class UserListTableViewDataSource<Model>: TableViewDataSource<Model> {
    @objc(tableView:canEditRowAtIndexPath:)
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return (tableView as! UserListTableView).allowsEditing
    }
    
    @objc(tableView:commitEditingStyle:forRowAtIndexPath:)
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let tableView = tableView as? UserListTableView {
                models.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.delegateInterceptor?.didDeleteRow(at: indexPath)
            }
        }
    }
}

extension UserListTableViewDataSource where Model == UserListCellModel {
    static func make(for modelArray: [UserListCellModel], reuseIdentifier: String = userListCellID) -> UserListTableViewDataSource {
        return UserListTableViewDataSource(models: modelArray, reuseIdentifier: reuseIdentifier) { (model, cell) in
            guard let cell = cell as? UserListCell else { return }
            cell.model = model
        }
    }
}
