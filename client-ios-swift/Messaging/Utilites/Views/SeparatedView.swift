/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

@IBDesignable
class SeparatedView: UIView, NibLoadable {
    @IBOutlet private weak var iconView: UIImageView!
    @IBInspectable private var icon: UIImage? {
        get { return iconView.image }
        set { iconView.image = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
    }
}
