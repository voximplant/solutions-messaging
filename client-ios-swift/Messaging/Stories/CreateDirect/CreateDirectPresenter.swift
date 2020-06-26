/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

final class CreateDirectPresenter:
    ControllerLifeCycleObserver,
    CreateDirectViewOutput,
    CreateDirectInteractorOutput,
    UserListOutput,
    MainQueuePerformable
{
    private weak var view: CreateDirectViewInput?
    var interactor: CreateDirectInteractorInput! // DI
    var router: CreateDirectRouterInput! // DI
    var userListInput: UserListInput! // DI
    
    var numberOfUsers: Int { interactor.numberOfUsers }
    
    init(view: CreateDirectViewInput) { self.view = view }
    
    // MARK: - UserListOutput
    func didSelectUser(at index: Int) {
        view?.showHUD(with: "Creating...")
        interactor.createDirect(with: interactor.getUser(at: IndexPath(row: index, section: 0)).id)
    }
    
    func getUser(at indexPath: IndexPath) -> User {
        interactor.getUser(at: indexPath)
    }
    
    func subscribeOnUserChanges(_ observer: DataSourceObserver<User>) {
        interactor.setupObservers(observer)
    }

    // MARK: - CreateDirectViewOutput
    // MARK: - User
    func viewDidLoad() {
        userListInput.type = .singlePick
    }
    
    func openCreateChannel() {
        router.showCreateChatStory(of: .channel)
    }
    
    func openCreateChat() {
        router.showCreateChatStory(of: .chat)
    }
    
    // MARK: - CreateDirectInteractorOutput
    func conversationCreated(_ conversation: Conversation) {
        onMainQueue {
            self.view?.hideHUD()
            self.router.showConversationScreen(with: conversation)
        }
    }
    
    func failedToCreateConversation(with error: Error) {
        onMainQueue {
            self.view?.hideHUD()
            self.view?.showError(error)
        }
    }
}
