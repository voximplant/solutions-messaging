/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol ParticipantsRouterInput: AnyObject {
    func showAddParticipantsScreen(with conversation: Conversation)
    func showAddAdminsScreen(with conversation: Conversation)
    func showConversationsScreen(with conversation: Conversation)
    func viewDidAppear()
}

protocol ParticipantsRouterOutput: AnyObject {
    func requestConversationModel() -> Conversation
}

final class ParticipantsRouter: NSObject, ParticipantsRouterInput, UINavigationControllerDelegate {
    weak var viewController: ParticipantsViewController?
    weak var output: ParticipantsRouterOutput?
    
    init(viewController: ParticipantsViewController) { self.viewController = viewController }
    
    // MARK: - ParticipantsRouterInput -
    func viewDidAppear() { viewController?.navigationController?.delegate = self }
    
    func showAddParticipantsScreen(with conversation: Conversation) {
        let controller = AddParticipantsRouter.moduleEntryController(with: .members(model: conversation))
        viewController?.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showAddAdminsScreen(with conversation: Conversation) {
        let controller = AddParticipantsRouter.moduleEntryController(with: .admins(model: conversation))
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
    
    // MARK: Entry Point -
    static func moduleEntryController(with type: ParticipantsModuleType) -> ParticipantsViewController {
        let viewController = UIStoryboard.main.instantiateViewController(withIdentifier: ParticipantsViewController.self) as! ParticipantsViewController
        
        let configurator: ParticipantsConfiguratorProtocol = ParticipantsConfigurator()
        configurator.configure(with: viewController, and: type)
        
        return viewController
    }
    
    // MARK: - UINavigationControllerDelegate -
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard let output = output else { return }
        if let viewController = viewController as? ConversationInfoViewController {
            viewController.output.didAppearAfterRemoving(with: output.requestConversationModel())
        }
    }
}
