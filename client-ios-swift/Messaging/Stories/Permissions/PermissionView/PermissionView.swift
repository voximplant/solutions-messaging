/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

@IBDesignable
final class PermissionView: UIView, NibLoadable {
    @IBOutlet private weak var isAllowedSwitch: UISwitch!
    @IBOutlet private weak var nameLabel: UILabel!
    
    @IBInspectable
    var name: String? {
        get { nameLabel.text }
        set { nameLabel.text = newValue }
    }
    
    @IBInspectable
    var isAllowed: Bool {
        get { isAllowedSwitch.isOn }
        set { isAllowedSwitch.setOn(newValue, animated: true) }
    }
    
    var isAllowedChangedObserver: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupFromNib()
    }
    
    @IBAction private func isAllowedChanged(_ sender: UISwitch) {
        isAllowedChangedObserver?()
    }
}
