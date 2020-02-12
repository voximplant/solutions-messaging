/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ConversationInfoConfiguratorProtocol {
    func configure(with viewController: ConversationInfoViewController, and conversation: Conversation)
}

final class ConversationInfoConfigurator: ConversationInfoConfiguratorProtocol {
    func configure(with viewController: ConversationInfoViewController, and conversation: Conversation) {
        let presenter = ConversationInfoPresenter(view: viewController, conversation: conversation)
        let interactor = ConversationInfoInteractor(output: presenter)
        let router = ConversationInfoRouter(viewController: viewController)
        
        viewController.output = presenter
        presenter.interactor = interactor
        presenter.router = router
        router.output = presenter
    }
}
