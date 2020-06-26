/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class EventTableCell: UITableViewCell, ConfigurableCell {
    typealias Model = EventTableCellModel
    
    @IBOutlet private weak var eventTextLabel: UILabel!
    
    func configure(with model: Model) {
        eventTextLabel.text = model.text
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        transform = CGAffineTransform(rotationAngle: (-.pi)) // because chat cells are reverted
    }
}
