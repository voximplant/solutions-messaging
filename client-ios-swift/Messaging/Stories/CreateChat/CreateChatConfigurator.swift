/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol CreateChatConfiguratorProtocol: AnyObject {
    func configure(with viewController: CreateChatViewController, and type: Conversation.ConversationType)
}

final class CreateChatConfigurator: CreateChatConfiguratorProtocol {
    private let repositopy: Repository
    private let userDataSource: UserDataSource
    
    init(repository: Repository, userDataSource: UserDataSource) {
        self.repositopy = repository
        self.userDataSource = userDataSource
    }
    
    func configure(with viewController: CreateChatViewController, and type: Conversation.ConversationType) {
        let presenter = CreateChatPresenter(view: viewController)
        let userListPresenter = UserListPresenter(view: viewController.userListView, output: presenter)
        presenter.userListInput = userListPresenter
        viewController.userListView.output = userListPresenter
        viewController.output = presenter
        
        let interactor = CreateChatInteractor(output: presenter,
                                              repository: repositopy,
                                              userDataSource: userDataSource)
        let router = CreateChatRouter(viewController: viewController)
        
        presenter.interactor = interactor
        presenter.router = router
        presenter.type = type
    }
}
