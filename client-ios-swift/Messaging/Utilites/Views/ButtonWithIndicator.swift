/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class ButtonWithIndicator: Button {
    private var activityIndicator: UIActivityIndicatorView!
    
    override func sharedInit() {
        super.sharedInit()
        activityIndicator = UIActivityIndicatorView(frame: bounds)
        activityIndicator.isHidden = true
        activityIndicator.color = .white
        addSubview(activityIndicator)
    }
    
    func showLoading(_ show: Bool) {
        isUserInteractionEnabled = !show
        activityIndicator.isHidden = !show
        show
            ? activityIndicator.startAnimating()
            : activityIndicator.stopAnimating()
    }
    
}

