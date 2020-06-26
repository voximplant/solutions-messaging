/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol TableViewControlling {
    var tableView: UITableView { get }
    var animationStyle: UITableView.RowAnimation { get }
    
    func refresh()
    func beginUpdate()
    func endUpdate()
    func updateRow(at indexPath: IndexPath)
    func removeRow(at indexPath: IndexPath)
    func insertRow(at indexPath: IndexPath)
    func moveRow(from indexPath: IndexPath, to newIndexPath: IndexPath)
}

extension TableViewControlling {
    var animationStyle: UITableView.RowAnimation { .automatic }
    
    func refresh() {
        tableView.reloadData()
    }
    
    func beginUpdate() {
        tableView.beginUpdates()
    }
    
    func endUpdate() {
        tableView.endUpdates()
    }
    
    func updateRow(at indexPath: IndexPath) {
        if tableView.cellForRow(at: indexPath) != nil {
            tableView.reloadRows(at: [indexPath], with: animationStyle)
        }
    }
    
    func removeRow(at indexPath: IndexPath) {
        if tableView.cellForRow(at: indexPath) != nil {
            tableView.deleteRows(at: [indexPath], with: animationStyle)
        }
    }
    
    func insertRow(at indexPath: IndexPath) {
        tableView.insertRows(at: [indexPath], with: animationStyle)
    }
    
    func moveRow(from indexPath: IndexPath, to newIndexPath: IndexPath) {
        tableView.moveRow(at: indexPath, to: newIndexPath)
    }
}
