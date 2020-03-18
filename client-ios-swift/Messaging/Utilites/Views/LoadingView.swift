/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

enum LoadingViewState: Equatable {
    case active (text: String)
    case inactive
}

final class LoadingView: UIView, NibLoadable {
    private var state: LoadingViewState = .inactive
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var contentView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
        sharedInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupFromNib()
        sharedInit()
    }
    
    private func sharedInit() {
        contentView.layer.cornerRadius = 12
    }
    
    func set(state: LoadingViewState) {
        if self.state == state { return }
        
        if state == .inactive {
            if activityIndicator.isAnimating { activityIndicator.stopAnimating() }
        } else if case .active(let text) = state {
            if !activityIndicator.isAnimating { activityIndicator.startAnimating() }
            textLabel.text = text
        }
        self.state = state
    }
}
