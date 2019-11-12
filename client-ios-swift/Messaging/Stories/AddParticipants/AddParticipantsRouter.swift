/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol AddParticipantsRouterInput: AnyObject {
    func viewDidAppear()
    func showConversationsScreen(with conversation: Conversation)
}

protocol AddParticipantsRouterOutput: AnyObject {
    func requestConversationModel() -> Conversation
}

class AddParticipantsRouter: NSObject, AddParticipantsRouterInput, UINavigationControllerDelegate {
    weak var viewController: AddParticipantsViewController?
    weak var output: AddParticipantsRouterOutput?
    
    init(viewController: AddParticipantsViewController) { self.viewController = viewController }
    
    // MARK: - AddParticipantsRouterInput
    func viewDidAppear() {
        viewController?.navigationController?.delegate = self
    }
    
    func showConversationsScreen(with conversation: Conversation) {
        guard let conversationsViewController = viewController?.navigationController?.viewControllers
            .first(where:
                { $0 is ConversationsViewController }) as? ConversationsViewController
            else { return }
        conversationsViewController.output.didAppearAfterRemoving(conversation: conversation)
        viewController?.navigationController?.popToViewController(conversationsViewController, animated: true)
    }
    
    // MARK: - Entry Point
    static func moduleEntryController(with type: AddParticipantsModuleType) -> UIViewController {
        let viewController = UIStoryboard.main.instantiateViewController(withIdentifier: AddParticipantsViewController.self)
            as! AddParticipantsViewController
        
        let configurator = AddParticipantsConfigurator()
        configurator.configure(with: viewController, and: type)
        
        return viewController
    }
    
    // MARK: - UINavigationControllerDelegate
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard let output = output else { return }
        if let viewController = viewController as? ConversationInfoViewController {
            viewController.output.didAppearAfterAdding(with: output.requestConversationModel())
        }
        else if let viewController = viewController as? ParticipantsViewController {
            viewController.output.didAppearAfterAdding(with: output.requestConversationModel())
        }
    }
    
}
