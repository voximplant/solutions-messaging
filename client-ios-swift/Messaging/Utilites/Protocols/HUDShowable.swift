/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol HUDShowable {
    func showHUD(with title: String)
    func hideHUD()
    func showError(_ error: Error)
    func showError(_ text: String)
}

extension HUDShowable where Self: UIViewController {
    func showHUD(with title: String) { UIHelper.showLoading(with: title) }
    func hideHUD() { UIHelper.hideLoading() }
    func showError(_ error: Error) {
        if let error = error as? VoxDemoError {
            UIHelper.ShowError(error: error.localizedDescription, controller: self)
        } else {
            UIHelper.ShowError(error: error.localizedDescription, controller: self)
        }
    }
    func showError(_ text: String) { UIHelper.ShowError(error: text, controller: self) }
}

