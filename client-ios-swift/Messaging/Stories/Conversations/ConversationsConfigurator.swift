/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ConversationsConfiguratorProtocol: AnyObject {
    func configure(with viewController: ConversationsViewController)
}

final class ConversationsConfigurator: ConversationsConfiguratorProtocol {
    func configure(with viewController: ConversationsViewController) {
        let presenter = ConversationsPresenter(view: viewController)
        let interactor = ConversationsInteractor(output: presenter)
        let router = ConversationsRouter(viewController: viewController)

        viewController.output = presenter
        presenter.interactor = interactor
        presenter.router = router
    }
}
