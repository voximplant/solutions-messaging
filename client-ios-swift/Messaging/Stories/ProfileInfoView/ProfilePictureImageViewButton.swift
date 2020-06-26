/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit
import SelectableStackView

final class ProfilePictureImageViewButton: Button, ObservableBySelectableStackView {
    var observer: ((ObservableBySelectableStackView) -> Void)?
    var handlingSelfSelection: Bool = true
    override var isSelected: Bool {
        didSet {
            alpha = isSelected ? 1 : 0.55
        }
    }
    override var buttonType: UIButton.ButtonType { .custom }
    
    convenience init(picture: Picture) {
        self.init()
        setImage(picture.uiImage, for: .normal)
        setImage(picture.uiImage, for: .highlighted)
        setImage(picture.uiImage, for: .selected)
    }
    
    override func sharedInit() {
        super.sharedInit()
        adjustsImageWhenHighlighted = false
        addTarget(self, action: #selector(touchUp), for: .touchUpInside)
        alpha = isSelected ? 1 : 0.55
        clipsToBounds = true
        layer.cornerRadius = 8
    }
    
    @objc private func touchUp() {
        isSelected.toggle()
        observer?(self)
    }
}
