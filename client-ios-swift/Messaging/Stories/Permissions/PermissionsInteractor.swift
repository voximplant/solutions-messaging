/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol PermissionsInteractorInput {
    var permissions: Permissions { get }
    func editPermissions(_ newPermissions: Permissions)
    
    func setupObservers()
    func removeObservers()
}

protocol PermissionsInteractorOutput: AnyObject {
    func permissionsChanged(_ permissions: Permissions)
    func conversationDisappeared()
    func failedToEditPermissions(with error: Error)
}

final class PermissionsInteractor: PermissionsInteractorInput {
    private weak var output: PermissionsInteractorOutput?
    private let repository: Repository
    private let conversationDataSource: ConversationDataSource
    private var conversationObserver: DataSourceObserver<Conversation>?
    
    private var activeConversation: Conversation
    var permissions: Permissions { activeConversation.permissions }
    
    init(output: PermissionsInteractorOutput,
         repository: Repository,
         conversationDataSource: ConversationDataSource,
         conversation: Conversation
    ) {
        self.output = output
        self.repository = repository
        self.conversationDataSource = conversationDataSource
        self.activeConversation = conversation
    }
    
    deinit {
        removeObservers()
    }
    
    // MARK: - PermissionsInteractorInput
    func setupObservers() {
        let conversationObserver = DataSourceObserver<Conversation>(
            contentWillChange: nil,
            contentDidChange: nil,
            didReceiveChange: { [weak self] change in
                guard let self = self else { return }
                switch change {
                case .delete(_):
                    self.removeObservers()
                    self.output?.conversationDisappeared()
                case .update(let conversation, _):
                    let permissionsChanged = conversation.permissions != self.activeConversation.permissions
                    self.activeConversation = conversation
                    if permissionsChanged {
                        self.output?.permissionsChanged(conversation.permissions)
                    }
                default:
                    break
                }
            }
        )
        self.conversationObserver = conversationObserver
        self.conversationDataSource.observeConversation(
            with: activeConversation.uuid,
            conversationObserver
        )
    }
    
    func removeObservers() {
        if let observer = conversationObserver {
            self.conversationDataSource.removeObserver(observer)
            self.conversationObserver = nil
        }
    }
    
    func editPermissions(_ newPermissions: Permissions) {
        repository.updateConversation(activeConversation, permissions: newPermissions) { [weak self] error in
            if let error = error {
                self?.output?.failedToEditPermissions(with: error)
            }
        }
    }
}
