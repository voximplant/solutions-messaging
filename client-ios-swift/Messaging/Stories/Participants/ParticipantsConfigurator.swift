/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ParticipantsConfiguratorProtocol: AnyObject {
    func configure(with viewController: ParticipantsViewController,
                   and type: ParticipantsModuleType,
                   conversation: Conversation)
}

final class ParticipantsConfigurator: ParticipantsConfiguratorProtocol {
    private let repositopy: Repository
    private let conversationDataSource: ConversationDataSource
    
    init(repository: Repository,
         conversationDataSource: ConversationDataSource
    ) {
        self.repositopy = repository
        self.conversationDataSource = conversationDataSource
    }
    
    func configure(
        with viewController: ParticipantsViewController,
        and type: ParticipantsModuleType,
        conversation: Conversation
    ) {
        let presenter = ParticipantsPresenter(
            view: viewController,
            type: type
        )
        let userListPresenter = UserListPresenter(
            view: viewController.userListView,
            output: presenter
        )
        presenter.userListInput = userListPresenter
        viewController.userListView.output = userListPresenter
        viewController.output = presenter
        let interactor = ParticipantsInteractor(
            output: presenter,
            repository: repositopy,
            conversationDataSource: conversationDataSource,
            conversation: conversation
        )
        let router = ParticipantsRouter(viewController: viewController)
        presenter.interactor = interactor
        presenter.router = router
    }
}
