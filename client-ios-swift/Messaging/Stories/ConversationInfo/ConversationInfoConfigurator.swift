/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ConversationInfoConfiguratorProtocol {
    func configure(with viewController: ConversationInfoViewController, and conversation: Conversation)
}

final class ConversationInfoConfigurator: ConversationInfoConfiguratorProtocol {
    private let repositopy: Repository
    private let conversationDataSource: ConversationDataSource
    
    required init(repository: Repository, authService: AuthService, conversationDataSource: ConversationDataSource) {
        self.repositopy = repository
        self.conversationDataSource = conversationDataSource
    }
    
    func configure(with viewController: ConversationInfoViewController, and conversation: Conversation) {
        let presenter = ConversationInfoPresenter(view: viewController)
        let userListPresenter = UserListPresenter(
            view: viewController.userListView,
            output: presenter
        )
        viewController.userListView.output = userListPresenter
        presenter.userListInput = userListPresenter
        viewController.output = presenter
        let interactor = ConversationInfoInteractor(
            output: presenter,
            repository: repositopy,
            conversationDataSource: conversationDataSource,
            conversation: conversation
        )
        let router = ConversationInfoRouter(viewController: viewController)
        presenter.interactor = interactor
        presenter.router = router
    }
}
