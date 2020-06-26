/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

protocol AddParticipantsRouterInput: AnyObject {
    func showConversationsScreen()
}

final class AddParticipantsRouter: AddParticipantsRouterInput {
    private weak var viewController: AddParticipantsViewController?
    
    init(viewController: AddParticipantsViewController) { self.viewController = viewController }
    
    // MARK: - AddParticipantsRouterInput
    func showConversationsScreen() {
        if let conversationsViewController = viewController?.navigationController?.viewControllers
            .first(where: { $0 is ConversationsViewController }) {
            viewController?.navigationController?.popToViewController(conversationsViewController, animated: true)
        }
    }
    
    // MARK: - Entry Point
    static func moduleEntryController(
        with type: AddParticipantsModuleType,
        conversation: Conversation
    ) -> AddParticipantsViewController {
        let viewController = Storyboard.convesation.instantiateViewController(of: AddParticipantsViewController.self)
        
        let configurator = StoryConfiguratorFactory.addParticipantsConfigurator
        configurator.configure(with: viewController, and: type, conversation: conversation)
        
        return viewController
    }
}
