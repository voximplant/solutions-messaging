/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

protocol ParticipantsRouterInput: AnyObject {
    func showAddParticipantsScreen(with conversation: Conversation)
    func showAddAdminsScreen(with conversation: Conversation)
    func showConversationsScreen()
}

final class ParticipantsRouter: ParticipantsRouterInput {
    private weak var viewController: ParticipantsViewController?
    
    init(viewController: ParticipantsViewController) {
        self.viewController = viewController
    }
    
    // MARK: - ParticipantsRouterInput -
    func showAddParticipantsScreen(with conversation: Conversation) {
        let controller = AddParticipantsRouter.moduleEntryController(with: .members, conversation: conversation)
        viewController?.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showAddAdminsScreen(with conversation: Conversation) {
        let controller = AddParticipantsRouter.moduleEntryController(with: .admins, conversation: conversation)
        viewController?.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showConversationsScreen() {
        guard let conversationsViewController = viewController?.navigationController?.viewControllers
            .first(where: { $0 is ConversationsViewController }) else {
                return
        }
        viewController?.navigationController?.popToViewController(conversationsViewController, animated: true)
    }
    
    // MARK: Entry Point -
    static func moduleEntryController(with type: ParticipantsModuleType, conversation: Conversation) -> ParticipantsViewController {
        let viewController = Storyboard.convesation.instantiateViewController(of: ParticipantsViewController.self)
        
        let configurator = StoryConfiguratorFactory.participantsConfigurator
        configurator.configure(with: viewController, and: type, conversation: conversation)
        
        return viewController
    }
}
