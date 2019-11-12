/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

class PictureSelectorViewCellModel {
    var imageName: String
    var isSelected: Bool
    
    init(imageName: String, isSelected: Bool) {
        self.imageName = imageName
        self.isSelected = isSelected
    }
}

class PictureSelectorViewCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var imageView: ImageView!
    @IBOutlet private weak var blurView: UIView!
    
    var model: PictureSelectorViewCellModel! {
        didSet {
            imageView.name = model.imageName
            isSelected = model.isSelected
        }
    }

    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: 0.2)
            { self.blurView.alpha = self.isSelected ? 0 : 0.6 }
        }
    }
    
}
