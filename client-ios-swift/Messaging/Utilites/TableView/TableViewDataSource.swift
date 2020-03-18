/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

class TableDataSource: NSObject, UITableViewDataSource {
    var items: [[CellConfigurator]]
    
    required init(items: [[CellConfigurator]]) {
        self.items = items
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = items[indexPath.section]
        let item = section[indexPath.row]
        
        let reuseID = type(of: item).reuseId
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        
        item.configure(cell: cell)
        
        return cell
    }
}
