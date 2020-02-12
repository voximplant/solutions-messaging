/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class RoundBarButtonItemWithActivity: UIBarButtonItem {
    private let frame = CGRect(x: 0, y: 0, width: 35, height: 35)
    private let transform = CGAffineTransform(translationX: 10, y: 0)
    private (set) var activityIndicator: UIActivityIndicatorView!
    private (set) var conversationButton: RoundButton!
    private (set) var profileImageView: ProfilePictureView!
    private var containerView: UIView!

    override init() {
        super.init()
        sharedInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }

    private func sharedInit() {
        setupActivityIndicator()
        setupImageView()
        setupButton()
        setupContainerView()
        customView = containerView
    }
    
    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(frame: frame)
    }
    
    private func setupImageView() {
        profileImageView = ProfilePictureView(frame: frame)
        profileImageView.backgroundColor = .clear
    }
    
    private func setupButton() {
        conversationButton = RoundButton(frame: frame)
        conversationButton.backgroundColor = .clear
    }
    
    private func setupContainerView() {
        containerView = UIView(frame: frame)
        containerView.addSubview(profileImageView)
        containerView.addSubview(conversationButton)
        containerView.addSubview(activityIndicator)
    }
}
