/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

class ViewController: UIViewController, UIIndicator {
    func showHUD(with title: String) { UIHelper.showLoading(with: title) }
    func hideHUD() { UIHelper.hideLoading() }
    func showError(with text: String) { UIHelper.ShowError(error: text, controller: self) }
}

protocol UIIndicator {
    func showHUD(with title: String)
    func hideHUD()
    func showError(with text: String)
}
