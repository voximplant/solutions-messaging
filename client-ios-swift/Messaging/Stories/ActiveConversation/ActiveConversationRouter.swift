/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol ActiveConversationRouterInput: AnyObject {
    func showConversationInfoScreen(with conversation: Conversation)
    func showConversationsScreen(with conversation: Conversation)
}

class ActiveConversationRouter: ActiveConversationRouterInput {
    weak var viewController: ActiveConversationViewController?
    
    init(viewController: ActiveConversationViewController) { self.viewController = viewController }
    
    // MARK: - ActiveConversationRouterInput -
    func showConversationInfoScreen(with conversation: Conversation) {
        viewController?.navigationController?.show(ConversationInfoRouter.moduleEntryController(with: conversation), sender: self)
    }
    
    func showConversationsScreen(with conversation: Conversation) {
        guard let conversationsViewController = viewController?.navigationController?.viewControllers
            .first(where:
                { $0 is ConversationsViewController }) as? ConversationsViewController
            else { return }
        viewController?.navigationController?.popToViewController(conversationsViewController, animated: true)
        conversationsViewController.output.didAppearAfterRemoving(conversation: conversation)
    }
    
    // MARK: - Entry Point -
    static func moduleEntryController(with conversation: Conversation) -> UIViewController {
        let viewController = UIStoryboard.main.instantiateViewController(withIdentifier: ActiveConversationViewController.self) as! ActiveConversationViewController
        
        let configurator: ActiveConversationConfiguratorProtocol = ActiveConversationConfigurator()
        configurator.configure(with: viewController, and: conversation)
        
        return viewController
    }
}
