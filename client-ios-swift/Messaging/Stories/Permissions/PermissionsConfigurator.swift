/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol PermissionsConfiguratorProtocol {
    func configure(with viewController: PermissionsViewController, and conversation: Conversation)
}

class PermissionsConfigurator: PermissionsConfiguratorProtocol {
    func configure(with viewController: PermissionsViewController, and conversation: Conversation) {
        let presenter = PermissionsPresenter(view: viewController, conversation: conversation)
        let interactor = PermissionsInteractor(output: presenter)
        let router = PermissionsRouter(viewController: viewController)
        
        viewController.output = presenter
        presenter.interactor = interactor
        presenter.router = router
        router.output = presenter
    }
}
