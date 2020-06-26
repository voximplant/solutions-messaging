/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ConversationsConfiguratorProtocol {
    func configure(with viewController: ConversationsViewController)
}

final class ConversationsConfigurator: ConversationsConfiguratorProtocol {
    private let conversationDataSource: ConversationDataSource
    
    init(conversationDataSource: ConversationDataSource) {
        self.conversationDataSource = conversationDataSource
    }
    
    func configure(with viewController: ConversationsViewController) {
        let presenter = ConversationsPresenter(view: viewController)
        let router = ConversationsRouter(viewController: viewController)
        let interactor = ConversationsInteractor(
            output: presenter,
            conversationDataSource: conversationDataSource
        )
        
        viewController.output = presenter
        presenter.interactor = interactor
        presenter.router = router
    }
}
