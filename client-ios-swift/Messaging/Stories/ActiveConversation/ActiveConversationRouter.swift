/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

protocol ActiveConversationRouterInput: AnyObject {
    func showConversationInfoScreen(with conversation: Conversation)
    func showConversationsScreen()
}

final class ActiveConversationRouter: ActiveConversationRouterInput {
    private weak var viewController: ActiveConversationViewController?
    
    init(viewController: ActiveConversationViewController) {
        self.viewController = viewController
    }
    
    // MARK: - ActiveConversationRouterInput -
    func showConversationInfoScreen(with conversation: Conversation) {
        viewController?.navigationController?.show(
            ConversationInfoRouter.moduleEntryController(with: conversation),
            sender: self
        )
    }
    
    func showConversationsScreen() {
        if let conversationsViewController = viewController?.navigationController?.viewControllers
            .first(where: { $0 is ConversationsViewController }) {
            viewController?.navigationController?.popToViewController(
                conversationsViewController,
                animated: true
            )
        }
    }
    
    // MARK: - Entry Point -
    static func moduleEntryController(with conversation: Conversation) -> ActiveConversationViewController {
        let viewController = Storyboard.convesation.instantiateViewController(of: ActiveConversationViewController.self)
        
        let configurator = StoryConfiguratorFactory.activeConversationConfigurator
        configurator.configure(with: viewController, and: conversation)
        
        return viewController
    }
}
