/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

class ImageView: UIImageView {
    var name: String? {
        didSet { if let name = name { image = UIImage(named: name) } }
    }
}

final class ProfilePictureView: ImageView, RoundViewProtocol {
    var isForUser: Bool = false
    var profileName: String?
    override var name: String? {
        didSet {
            guard let profileName = profileName else { return }
            image = ProfilePictureGenerator.generatePicture(with: name, and: profileName, for: self.bounds)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }
}
