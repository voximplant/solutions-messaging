/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

fileprivate let PermissionsCellID = "PermissionsTableViewCell"
fileprivate let PermissionsNibName = "PermissionsTableViewCell"

final class PermissionsTableView: TableView {
    override var cellID: String { return PermissionsCellID }
    override var nibName: String { return PermissionsNibName }
}

extension TableViewDataSource where Model == PermissionsCellModel {
    static func make(with modelArray: [PermissionsCellModel]) -> TableViewDataSource {
        return TableViewDataSource(models: modelArray, reuseIdentifier: PermissionsCellID) { (model, cell) in
            if let cell = cell as? PermissionsTableViewCell { cell.model = model }
        }
    }
}
