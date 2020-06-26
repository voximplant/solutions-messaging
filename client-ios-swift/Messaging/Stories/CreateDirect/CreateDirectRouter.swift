/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

protocol CreateDirectRouterInput: AnyObject {
    func showCreateChatStory(of type: Conversation.ConversationType)
    func showConversationScreen(with conversation: Conversation)
}

final class CreateDirectRouter: CreateDirectRouterInput {
    private weak var viewController: CreateDirectViewController?
    
    init(viewController: CreateDirectViewController) { self.viewController = viewController }
    
    // MARK: - CreateDirectRouterInput
    func showCreateChatStory(of type: Conversation.ConversationType) {
        viewController?.navigationController?.show(
            CreateChatRouter.moduleEntryController(with: type),
            sender: self
        )
    }
    
    func showConversationScreen(with conversation: Conversation) {
        let controller = ConversationsRouter.moduleEntryController
        var controllers = controller.viewControllers
        controllers.append(ActiveConversationRouter.moduleEntryController(with: conversation))
        controller.viewControllers = controllers
        viewController?.navigationController?.present(controller, animated: true)
    }
    
    // MARK: - Entry Point
    static var moduleEntryController: CreateDirectViewController {
        let configurator = StoryConfiguratorFactory.createDirectConfigurator
        let viewController = Storyboard.create.instantiateViewController(
            of: CreateDirectViewController.self
        )
        configurator.configure(with: viewController)
        return viewController
    }
}
