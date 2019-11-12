/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol CreateDirectRouterInput: AnyObject {
    func showCreateChatStory(of type: ConversationType, with users: [User])
    func showConversationScreen(with conversation: Conversation)
}

class CreateDirectRouter: CreateDirectRouterInput {
    
    weak var viewController: CreateDirectViewController!
    
    init(viewController: CreateDirectViewController) {
        self.viewController = viewController
    }
    
    // MARK: - CreateDirectRouterInput
    func showCreateChatStory(of type: ConversationType, with users: [User]) {
        viewController.navigationController?.show(CreateChatRouter.moduleEntryController(with: type, and: users), sender: self)
    }
    
    func showConversationScreen(with conversation: Conversation) {
        let controller = ConversationsRouter.moduleEntryController
        var controllers = controller.viewControllers
        controllers.append(ActiveConversationRouter.moduleEntryController(with: conversation))
        controller.viewControllers = controllers
        viewController.navigationController?.present(controller, animated: true, completion: nil)
    }
    
    // MARK: - Entry Point
    static var moduleEntryController: UIViewController {
        let configurator = CreateDirectConfigurator()
        let viewController = UIStoryboard.main.instantiateViewController(withIdentifier: CreateDirectViewController.self) as! CreateDirectViewController
        configurator.configure(with: viewController)
        return viewController
    }
}
