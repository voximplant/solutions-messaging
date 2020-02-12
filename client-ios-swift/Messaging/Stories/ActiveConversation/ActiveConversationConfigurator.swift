/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ActiveConversationConfiguratorProtocol: AnyObject {
    func configure(with viewController: ActiveConversationViewController, and conversation: Conversation)
}

final class ActiveConversationConfigurator: ActiveConversationConfiguratorProtocol {
    func configure(with viewController: ActiveConversationViewController, and conversation: Conversation) {
        let presenter = ActiveConversationPresenter(view: viewController, conversation: conversation)
        let interactor = ActiveConversationInteractor(output: presenter)
        let router = ActiveConversationRouter(viewController: viewController)
        
        viewController.output = presenter
        presenter.interactor = interactor
        presenter.router = router
    }
}
