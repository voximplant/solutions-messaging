/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit

fileprivate let placeholderColorKey = "placeholderLabel.textColor"

class CustomTextField: UITextField {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    private func setupUI() {
        layer.cornerRadius = 12
        clipsToBounds = true
        setValue(UIColor.gray, forKeyPath: placeholderColorKey)
    }
    
    @IBAction func nextField(sender: UITextField) {
        becomeFirstResponder()
    }
}
