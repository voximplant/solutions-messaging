/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol SettingsRouterInput: AnyObject {
    func showLoginStory()
}

final class SettingsRouter: SettingsRouterInput {
    weak var viewController: SettingsViewController!
    
    init(viewController: SettingsViewController) { self.viewController = viewController }    
    
    // MARK: - SettingsRouterInput
    func showLoginStory() {
        UIApplication.shared.keyWindow?.rootViewController = LoginRouter.moduleEntryController
    }
    
    // MARK: Entry Point
    static func moduleEntryController() -> UIViewController {
        let configurator = SettingsConfigurator()
        let viewController = UIStoryboard.main.instantiateViewController(withIdentifier: SettingsViewController.self) as! SettingsViewController
        configurator.configure(with: viewController)
        return viewController
    }
}
