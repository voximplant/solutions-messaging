/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol PermissionsConfiguratorProtocol {
    func configure(with viewController: PermissionsViewController, and conversation: Conversation)
}

final class PermissionsConfigurator: PermissionsConfiguratorProtocol {
    private let repositopy: Repository
    private let conversationDataSource: ConversationDataSource
    
    init(repository: Repository, conversationDataSource: ConversationDataSource) {
        self.repositopy = repository
        self.conversationDataSource = conversationDataSource
    }
    
    func configure(with viewController: PermissionsViewController, and conversation: Conversation) {
        let presenter = PermissionsPresenter(view: viewController)
        let interactor = PermissionsInteractor(
            output: presenter,
            repository: repositopy,
            conversationDataSource: conversationDataSource,
            conversation: conversation
        )
        let router = PermissionsRouter(viewController: viewController)
        viewController.output = presenter
        presenter.interactor = interactor
        presenter.router = router
    }
}
