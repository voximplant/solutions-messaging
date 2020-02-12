/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol SettingsConfiguratorProtocol: AnyObject {
    func configure(with viewController: SettingsViewController)
}

final class SettingsConfigurator: SettingsConfiguratorProtocol {
    func configure(with viewController: SettingsViewController) {
        let presenter = SettingsPresenter(view: viewController)
        let interactor = SettingsInteractor(output: presenter)
        let router = SettingsRouter(viewController: viewController)
        
        viewController.output = presenter
        presenter.interactor = interactor
        presenter.router = router
    }
    
}
