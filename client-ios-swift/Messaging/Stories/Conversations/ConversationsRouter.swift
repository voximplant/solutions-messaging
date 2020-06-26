/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol ConversationsRouterInput: AnyObject {
    func showActiveConversationScreen(with conversation: Conversation)
    func showSettingsScreen()
    func showNewConversationScreen()
    func showLoginStory()
}

final class ConversationsRouter: ConversationsRouterInput {
    private weak var viewController: ConversationsViewController?
    
    init(viewController: ConversationsViewController) { self.viewController = viewController }
    
    // MARK: - ConversationsRouterInput -
    func showSettingsScreen() {
        viewController?.navigationController?.show(
            SettingsRouter.moduleEntryController(),
            sender: self
        )
    }
    
    func showNewConversationScreen() {
        viewController?.navigationController?.show(
            CreateDirectRouter.moduleEntryController,
            sender: self
        )
    }
    
    func showLoginStory() {
        UIApplication.shared.keyWindow?.rootViewController = LoginRouter.moduleEntryController
    }
    
    func showActiveConversationScreen(with conversation: Conversation) {
        viewController?.navigationController?.show(
            ActiveConversationRouter.moduleEntryController(with: conversation),
            sender: self
        )
    }
    
    // MARK: - Entry Point -
    static var moduleEntryController: UINavigationController {
        let navigationController = Storyboard.main
            .instantiateViewController(
                withIdentifier: String(describing: ConversationsViewController.self)
            ) as! UINavigationController
        
        let viewController = navigationController.viewControllers.first
            as! ConversationsViewController
        
        let configurator = StoryConfiguratorFactory.conversationsConfigurator
        configurator.configure(with: viewController)
        
        return navigationController
    }
}
