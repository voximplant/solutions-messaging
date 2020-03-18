/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol PermissionSwitchDelegate: AnyObject {
    func didChangeSwitchValue(in cell: PermissionsTableViewCell)
}

struct PermissionsCellModel {
    let name: String
    var isAllowed: Bool
    var delegate: PermissionSwitchDelegate
}

final class PermissionsTableViewCell: UITableViewCell, ConfigurableCell {
    typealias Model = PermissionsCellModel
    
    weak var delegate: PermissionSwitchDelegate?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var isAllowedSwitch: UISwitch!
    
    func configure(with model: PermissionsCellModel) {
        nameLabel.text = model.name
        isAllowedSwitch.isOn = model.isAllowed
        delegate = model.delegate
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        delegate?.didChangeSwitchValue(in: self)
    }
}
