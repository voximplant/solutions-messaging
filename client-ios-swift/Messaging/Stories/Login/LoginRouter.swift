/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol LoginRouterInput: AnyObject {
    func showConversationsStory()
}

class LoginRouter: LoginRouterInput {
    weak var viewController: LoginViewController?
    
    init(viewController: LoginViewController) { self.viewController = viewController }
    
    // MARK: - LoginRouterInput
    func showConversationsStory() {
        viewController?.present(ConversationsRouter.moduleEntryController, animated: true, completion: nil)
    }
    
    // MARK: - Entry Point
    static var moduleEntryController: UIViewController {
        let viewController = UIStoryboard.main.instantiateViewController(withIdentifier: LoginViewController.self) as! LoginViewController
        
        let configurator: LoginConfiguratorProtocol = LoginConfigurator()
        configurator.configure(with: viewController)
        
        return viewController
    }
}

