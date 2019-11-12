/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol ConversationInfoRouterInput: AnyObject {
    func showAddParticipantsScreen(with conversation: Conversation)
    func showPermissionsScreen(with conversation: Conversation)
    func showMembersScreen(with conversation: Conversation)
    func showAdminsScreen(with conversation: Conversation)
    func showConversationsScreen(with conversation: Conversation)
    func viewDidAppear()
}

protocol ConversationInfoRouterOutput: AnyObject {
    func requestConversation() -> Conversation
}

class ConversationInfoRouter: NSObject, ConversationInfoRouterInput, UINavigationControllerDelegate {
    weak var viewController: ConversationInfoViewController?
    weak var output: ConversationInfoRouterOutput?
    
    required init(viewController: ConversationInfoViewController) {
        super.init()
        self.viewController = viewController
    }

    // MARK: - ConversationInfoRouterInput
    func viewDidAppear() {
        self.viewController?.navigationController?.delegate = self
    }
    
    func showAddParticipantsScreen(with conversation: Conversation) {
        let controller = AddParticipantsRouter.moduleEntryController(with: .members(model: conversation))
        viewController?.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showPermissionsScreen(with conversation: Conversation) {
        let controller = PermissionsRouter.moduleEntryController(with: conversation)
        viewController?.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showMembersScreen(with conversation: Conversation) {
        let controller = ParticipantsRouter.moduleEntryController(with: .members(model: conversation))
        viewController?.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showAdminsScreen(with conversation: Conversation) {
        let controller = ParticipantsRouter.moduleEntryController(with: .admins(model: conversation))
        viewController?.navigationController?.pushViewController(controller, animated: true)
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
    static func moduleEntryController(with conversation: Conversation) -> ConversationInfoViewController {
        let configurator: ConversationInfoConfiguratorProtocol = ConversationInfoConfigurator()
        let viewController = UIStoryboard.main.instantiateViewController(withIdentifier: ConversationInfoViewController.self)
            as! ConversationInfoViewController
        configurator.configure(with: viewController, and: conversation)
        return viewController
    }
    
    // MARK: - UINavigationControllerDelegate
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard let output = output else { return }
        if let viewController = viewController as? ActiveConversationViewController {
            viewController.output.didAppearAfterEditing(with: output.requestConversation())
        }
    }
}
