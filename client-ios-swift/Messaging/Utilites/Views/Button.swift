/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

@IBDesignable
class Button: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    func sharedInit() {
        backgroundColor = VoxColor.button
        layer.cornerRadius = 12
        addTarget(self, action: #selector(backToNormalSize(_:)), for: [.touchUpInside, .touchDragOutside, .touchCancel, .touchUpOutside])
        addTarget(self, action: #selector(decreaseButtonSize(_:)), for: [.touchDown, .touchDragInside])
    }
    
    @objc private func decreaseButtonSize(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1, animations: { sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95) })
    }
    
    @objc private func backToNormalSize(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) { sender.transform = CGAffineTransform.identity }
    }
}
