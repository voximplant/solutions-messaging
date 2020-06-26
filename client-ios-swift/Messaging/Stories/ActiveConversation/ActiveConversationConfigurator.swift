/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ActiveConversationConfiguratorProtocol: AnyObject {
    func configure(with viewController: ActiveConversationViewController, and conversation: Conversation)
}

final class ActiveConversationConfigurator: ActiveConversationConfiguratorProtocol {
    private let repositopy: Repository
    private let conversationDataSource: ConversationDataSource
    private let userDataSource: UserDataSource
    private let eventDataSource: EventDataSource
    
    required init(
        repository: Repository,
        conversationDataSource: ConversationDataSource,
        userDataSource: UserDataSource,
        eventDataSource: EventDataSource
    ) {
        self.repositopy = repository
        self.conversationDataSource = conversationDataSource
        self.userDataSource = userDataSource
        self.eventDataSource = eventDataSource
    }
    
    func configure(with viewController: ActiveConversationViewController, and conversation: Conversation) {
        let presenter = ActiveConversationPresenter(view: viewController)
        let interactor = ActiveConversationInteractor(
            output: presenter,
            repository: repositopy,
            conversation: conversation,
            eventDataSource: eventDataSource,
            userDataSource: userDataSource,
            conversationDataSource: conversationDataSource
        )
        let router = ActiveConversationRouter(viewController: viewController)
        
        viewController.output = presenter
        presenter.interactor = interactor
        presenter.router = router
    }
}
