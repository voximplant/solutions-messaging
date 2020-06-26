/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

protocol ConversationInfoRouterInput: AnyObject {
    func showAddParticipantsScreen(with conversation: Conversation)
    func showPermissionsScreen(with conversation: Conversation)
    func showMembersScreen(with conversation: Conversation)
    func showAdminsScreen(with conversation: Conversation)
    func showConversationsScreen()
}

final class ConversationInfoRouter: ConversationInfoRouterInput {
    private weak var viewController: ConversationInfoViewController?
    
    init(viewController: ConversationInfoViewController) { self.viewController = viewController }

    // MARK: - ConversationInfoRouterInput
    func showAddParticipantsScreen(with conversation: Conversation) {
        let controller = AddParticipantsRouter.moduleEntryController(with: .members, conversation: conversation)
        viewController?.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showPermissionsScreen(with conversation: Conversation) {
        let controller = PermissionsRouter.moduleEntryController(with: conversation)
        viewController?.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showMembersScreen(with conversation: Conversation) {
        let controller = ParticipantsRouter.moduleEntryController(with: .members, conversation: conversation)
        viewController?.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showAdminsScreen(with conversation: Conversation) {
        let controller = ParticipantsRouter.moduleEntryController(with: .admins, conversation: conversation)
        viewController?.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showConversationsScreen() {
        guard let conversationsViewController = viewController?.navigationController?.viewControllers
            .first(where: { $0 is ConversationsViewController }) else {
                return
        }
        viewController?.navigationController?.popToViewController(conversationsViewController, animated: true)
    }
    
    // MARK: - Entry Point
    static func moduleEntryController(with conversation: Conversation) -> ConversationInfoViewController {
        let configurator = StoryConfiguratorFactory.conversationInfoConfigurator
        let viewController = Storyboard.convesation.instantiateViewController(of: ConversationInfoViewController.self)
        configurator.configure(with: viewController, and: conversation)
        return viewController
    }
}
