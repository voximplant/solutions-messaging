/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol PermissionsRouterInput: AnyObject {
    func viewDidAppear()
    func showConversationsScreen(with conversation: Conversation)
}

protocol PermissionsRouterOutput: AnyObject {
    func requestConversationModel() -> Conversation
}

class PermissionsRouter: NSObject, PermissionsRouterInput, UINavigationControllerDelegate {
    weak var viewController: PermissionsViewController?
    weak var output: PermissionsRouterOutput?
    
    required init(viewController: PermissionsViewController) {
        super.init()
        self.viewController = viewController
    }
    
    // MARK: - PermissionsRouterInput
    func viewDidAppear() {
        self.viewController?.navigationController?.delegate = self
    }
    
    func showConversationsScreen(with conversation: Conversation) {
        guard let conversationsViewController = viewController?.navigationController?.viewControllers
            .first(where:
                { $0 is ConversationsViewController }) as? ConversationsViewController
            else { return }
        conversationsViewController.output.didAppearAfterRemoving(conversation: conversation)
        viewController?.navigationController?.popToViewController(conversationsViewController, animated: true)
    }
    
    // MARK: - Module Entry Point
    static func moduleEntryController(with conversation: Conversation) -> PermissionsViewController {
        let viewController = UIStoryboard.main.instantiateViewController(withIdentifier: PermissionsViewController.self)
            as! PermissionsViewController
        
        let configurator: PermissionsConfiguratorProtocol = PermissionsConfigurator()
        configurator.configure(with: viewController, and: conversation)
        
        return viewController
    }
    
    // MARK: - UINavigationControllerDelegate
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard let controller = viewController as? ConversationInfoViewController else { return }
        guard let conversation = output?.requestConversationModel() else { return }
        controller.output.didAppearAfterChangingPermissions(conversation)
    }
    
}
