/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol CreateChatRouterInput: AnyObject {
    func showConversationScreen(with conversation: Conversation)
}

final class CreateChatRouter: CreateChatRouterInput {
    weak var viewController: CreateChatViewController!
    
    init(viewController: CreateChatViewController) { self.viewController = viewController }
    
    func showConversationScreen(with conversation: Conversation) {
        let controller = ConversationsRouter.moduleEntryController
        var controllers = controller.viewControllers
        controllers.append(ActiveConversationRouter.moduleEntryController(with: conversation))
        controller.viewControllers = controllers
        viewController.navigationController?.present(controller, animated: true, completion: nil)
    }
    
    // MARK: Entry Point
    static func moduleEntryController(with type: ConversationType, and users: [User]) -> UIViewController {
        let viewController = UIStoryboard.main.instantiateViewController(withIdentifier: CreateChatViewController.self) as! CreateChatViewController
        
        let configurator = CreateChatConfigurator()
        configurator.configure(with: viewController, and: type, users: users)
        
        return viewController
    }
}
