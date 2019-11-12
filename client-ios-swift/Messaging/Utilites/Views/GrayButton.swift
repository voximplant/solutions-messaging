/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

@IBDesignable
class GrayButton: UIButton {
    private var pressed = false {
        didSet {
            UIView.transition(with: self, duration: 0.2, options: [.allowUserInteraction, .transitionCrossDissolve], animations:
                {
                    if #available(iOS 13.0, *) { self.backgroundColor = self.pressed ? UIColor.separator : .clear }
                    else { self.backgroundColor = self.pressed ? .lightGray : .clear }
                    self.isHighlighted = self.pressed
                })
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        addTarget(self, action: #selector(cancelButtonPress(_:)), for: [.touchUpInside, .touchDragOutside, .touchCancel, .touchUpOutside])
        addTarget(self, action: #selector(buttonPressed(_:)), for: [.touchDown, .touchDragInside])
    }
    
    @objc func buttonPressed(_ sender: UIButton) { pressed = true }
    @objc func cancelButtonPress(_ sender: UIButton) { pressed = false }
}
