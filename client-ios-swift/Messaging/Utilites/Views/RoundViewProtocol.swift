/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol RoundViewProtocol: UIView { }

extension RoundViewProtocol {
    func sharedInit() {
        clipsToBounds = true
        layer.cornerRadius = frame.height / 2
    }
}

final class RoundView: UIView, RoundViewProtocol {
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }
}

final class RoundImageView: ImageView, RoundViewProtocol {
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }
}

final class RoundButton: UIButton, RoundViewProtocol {
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }
}

