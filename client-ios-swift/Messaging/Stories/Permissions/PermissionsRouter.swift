/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

protocol PermissionsRouterInput: AnyObject {
    func showConversationsScreen()
}

final class PermissionsRouter: PermissionsRouterInput {
    private weak var viewController: PermissionsViewController?
    
    init(viewController: PermissionsViewController) { self.viewController = viewController }
    
    // MARK: - PermissionsRouterInput
    func showConversationsScreen() {
        if let conversationsViewController = viewController?.navigationController?.viewControllers
            .first(where:  { $0 is ConversationsViewController }) {
            viewController?.navigationController?.popToViewController(conversationsViewController, animated: true)
        }
    }
    
    // MARK: - Module Entry Point
    static func moduleEntryController(with conversation: Conversation) -> PermissionsViewController {
        let viewController = Storyboard.convesation.instantiateViewController(of: PermissionsViewController.self)
        
        let configurator = StoryConfiguratorFactory.permissionsConfigurator
        configurator.configure(with: viewController, and: conversation)
        
        return viewController
    }
}
