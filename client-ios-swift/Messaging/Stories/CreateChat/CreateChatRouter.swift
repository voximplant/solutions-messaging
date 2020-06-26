/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

protocol CreateChatRouterInput: AnyObject {
    func showConversationScreen(with conversation: Conversation)
}

final class CreateChatRouter: CreateChatRouterInput {
    private weak var viewController: CreateChatViewController?
    
    init(viewController: CreateChatViewController) { self.viewController = viewController }
    
    // MARK: - CreateChatRouterInput
    func showConversationScreen(with conversation: Conversation) {
        let controller = ConversationsRouter.moduleEntryController
        var controllers = controller.viewControllers
        controllers.append(ActiveConversationRouter.moduleEntryController(with: conversation))
        controller.viewControllers = controllers
        viewController?.navigationController?.present(
            controller,
            animated: true,
            completion: nil
        )
    }
    
    // MARK: - Entry Point
    static func moduleEntryController(with type: Conversation.ConversationType)
        -> CreateChatViewController {
        
        let viewController = Storyboard.create.instantiateViewController(
            of: CreateChatViewController.self
        )
        
        let configurator = StoryConfiguratorFactory.createChatConfigurator
        configurator.configure(with: viewController, and: type)
        
        return viewController
    }
}
