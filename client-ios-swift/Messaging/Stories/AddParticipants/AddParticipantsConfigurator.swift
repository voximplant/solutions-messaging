/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol AddParticipantsConfiguratorProtocol: AnyObject {
    func configure(with viewController: AddParticipantsViewController, and type: AddParticipantsModuleType, conversation: Conversation)
}

final class AddParticipantsConfigurator: AddParticipantsConfiguratorProtocol {
    private let repositopy: Repository
    private let conversationDataSource: ConversationDataSource
    private let userDataSource: UserDataSource
    
    required init(repository: Repository,
                  authService: AuthService,
                  conversationDataSource: ConversationDataSource,
                  userDataSource: UserDataSource
    ) {
        self.repositopy = repository
        self.conversationDataSource = conversationDataSource
        self.userDataSource = userDataSource
    }
    
    func configure(with viewController: AddParticipantsViewController, and type: AddParticipantsModuleType, conversation: Conversation) {
        let presenter = AddParticipantsPresenter(view: viewController, type: type)
        let userListPresenter = UserListPresenter(
            view: viewController.userListView,
            output: presenter
        )
        presenter.userListInput = userListPresenter
        viewController.userListView.output = userListPresenter
        viewController.output = presenter
        let interactor = AddParticipantsInteractor(
            output: presenter,
            repository: repositopy,
            conversationDataSource: conversationDataSource,
            userDataSource: userDataSource,
            conversation: conversation
        )
        let router = AddParticipantsRouter(viewController: viewController)
        presenter.interactor = interactor
        presenter.router = router
    }
}
