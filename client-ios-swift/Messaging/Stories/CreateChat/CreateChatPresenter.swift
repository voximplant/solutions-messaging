/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

final class CreateChatPresenter:
    ControllerLifeCycleObserver,
    CreateChatViewOutput,
    CreateChatInteractorOutput,
    UserListOutput,
    MainQueuePerformable
{
    private weak var view: CreateChatViewInput?
    var interactor: CreateChatInteractorInput! // DI
    var router: CreateChatRouterInput! // DI
    var userListInput: UserListInput! // DI
    var type: Conversation.ConversationType! // DI
    
    var numberOfUsers: Int { interactor.numberOfUsers }
    private var selectedUsers: Set<User.ID> { userListInput.selectedUserIDs }
    
    init(view: CreateChatViewInput) { self.view = view }
    
    // MARK: - UserListOutput
    func getUser(at indexPath: IndexPath) -> User {
        interactor.getUser(at: indexPath)
    }
    
    func subscribeOnUserChanges(_ observer: DataSourceObserver<User>) {
        interactor.setupObservers(observer)
    }
    
    // MARK: - CreateChatViewOutput
    func viewDidLoad() {
        userListInput.type = .multiplePick
        view?.conversationInfoView.setState(.initial(type: type == .chat ? .groupChat : .channel))
        view?.title = "New \(type == .chat ? "Chat" : "Channel")"
        view?.conversationInfoView.setModel(ProfileInfoView.ProfileInfoViewModel(
            title: "",
            pictureName: nil,
            description: nil,
            isUber: true,
            isPublic: false)
        )
        view?.conversationInfoView.setState(.editing)
    }
    
    // MARK: - CreateChatInteractorOutput
    func createChat() {
        guard let view = view else { return }
        guard !selectedUsers.isEmpty else { return }
        guard let name = view.conversationInfoView.title,
            !name.isEmpty else {
                view.showError("Must enter title")
                return
        }
        let imageName = view.conversationInfoView.profileImageView.name
        let description = view.conversationInfoView.descriptionText ?? ""
        
        view.allowInteraction(false)
        view.showHUD(with: "Creating...")
        
        if type == .chat {
            interactor.createConversation(
                title: name,
                users: selectedUsers,
                imageName: imageName,
                description: description,
                isPublic: view.conversationInfoView.isPublic ?? false,
                isUber: view.conversationInfoView.isUber ?? false
            )
        }
        if type == .channel {
            interactor.createChannel(
                title: name,
                users: selectedUsers,
                imageName: imageName,
                description: description
            )
        }
    }
    
    func chatCreated(_ conversation: Conversation) {
        onMainQueue {
            self.view?.hideHUD()
            self.router.showConversationScreen(with: conversation)
        }
    }
    
    func failedToCreateChat(with error: Error) {
        onMainQueue {
            self.view?.hideHUD()
            self.view?.showError(error)
            self.view?.allowInteraction(true)
        }
    }
}
