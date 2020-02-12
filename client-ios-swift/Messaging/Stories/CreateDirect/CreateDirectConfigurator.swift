/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol CreateDirectConfiguratorProtocol: AnyObject {
    func configure(with viewController: CreateDirectViewController)
}

final class CreateDirectConfigurator: CreateDirectConfiguratorProtocol {
    func configure(with viewController: CreateDirectViewController) {
        let presenter = CreateDirectPresenter(view: viewController)
        let interactor = CreateDirectInteractor(output: presenter)
        let router = CreateDirectRouter(viewController: viewController)
        
        viewController.output = presenter
        presenter.interactor = interactor
        presenter.router = router
    }
}
