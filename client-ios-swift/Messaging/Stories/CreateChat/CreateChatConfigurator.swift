/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol CreateChatConfiguratorProtocol: AnyObject {
    func configure(with viewController: CreateChatViewController, and type: ConversationType, users: [User])
}

class CreateChatConfigurator: CreateChatConfiguratorProtocol {
    func configure(with viewController: CreateChatViewController, and type: ConversationType, users: [User]) {
        let presenter = CreateChatPresenter(view: viewController, users: users)
        let interactor = CreateChatInteractor(output: presenter)
        let router = CreateChatRouter(viewController: viewController)
        
        viewController.output = presenter
        presenter.interactor = interactor
        presenter.router = router
        presenter.type = type
    }
}
