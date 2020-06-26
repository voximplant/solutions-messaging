/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol SettingsRouterInput: AnyObject {
    func showLoginStory()
}

final class SettingsRouter: SettingsRouterInput {
    private weak var viewController: SettingsViewController?
    
    init(viewController: SettingsViewController) {
        self.viewController = viewController
    }
    
    // MARK: - SettingsRouterInput
    func showLoginStory() {
        UIApplication.shared.keyWindow?.rootViewController = LoginRouter.moduleEntryController
    }
    
    // MARK: Entry Point
    static func moduleEntryController() -> SettingsViewController {
        let configurator = StoryConfiguratorFactory.settingsConfigurator
        let viewController = Storyboard.main.instantiateViewController(of: SettingsViewController.self)
        configurator.configure(with: viewController)
        return viewController
    }
}
