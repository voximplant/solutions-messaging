/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

protocol LoginRouterInput: AnyObject {
    func showConversationsStory()
}

final class LoginRouter: LoginRouterInput {
    weak var viewController: LoginViewController?
    
    init(viewController: LoginViewController) { self.viewController = viewController }
    
    // MARK: - LoginRouterInput
    func showConversationsStory() {
        viewController?.present(ConversationsRouter.moduleEntryController, animated: true, completion: nil)
    }
    
    // MARK: - Entry Point
    static var moduleEntryController: LoginViewController {
        let viewController = Storyboard.login.instantiateViewController(of: LoginViewController.self)
        
        let configurator = StoryConfiguratorFactory.loginConfigurator
        configurator.configure(with: viewController)
        
        return viewController
    }
}

