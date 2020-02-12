/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class LoadingView: UIView, NibLoadable {
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var contentView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupFromNib()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.layer.cornerRadius = 12
        alpha = 0
    }
    
    func showLoading(with text: String) {
        UIView.animate(withDuration: 0.5) {
            self.activityIndicator.startAnimating()
            self.contentView.layer.cornerRadius = 12
            self.textLabel.text = text
            self.alpha = 1
        }
    }
    
    func updateLoading(with text: String) {
        UIView.animate(withDuration: 0.5) {
            self.textLabel.text = text
        }
    }
    
    func hideLoading() {
        UIView.animate(withDuration: 0.5) {
            self.activityIndicator.stopAnimating()
            self.alpha = 1
        }
    }
}
