/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class ActiveConversationTableDataSource: NSObject, UITableViewDataSource {
    private let numberOfItems: () -> Int
    private let configurator: (IndexPath) -> CellConfigurator
    
    required init(numberOfItems: @escaping () -> Int,
                  configurator: @escaping (IndexPath) -> CellConfigurator) {
        self.numberOfItems = numberOfItems
        self.configurator = configurator
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        numberOfItems()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = configurator(indexPath)
        let reuseID = type(of: item).reuseId
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        
        item.configure(cell: cell)
        
        return cell
    }
}
