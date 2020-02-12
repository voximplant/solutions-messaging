/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol LoginConfiguratorProtocol: AnyObject {
    func configure(with viewController: LoginViewController)
}

final class LoginConfigurator: LoginConfiguratorProtocol {
    func configure(with viewController: LoginViewController) {
        let presenter = LoginPresenter(view: viewController)
        let interactor = LoginInteractor(output: presenter)
        let router = LoginRouter(viewController: viewController)
        
        viewController.output = presenter
        presenter.interactor = interactor
        presenter.router = router
    }
}
