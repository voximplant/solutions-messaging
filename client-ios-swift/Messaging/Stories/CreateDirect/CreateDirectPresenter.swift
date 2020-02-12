/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

final class CreateDirectPresenter: Presenter, CreateDirectViewOutput, CreateDirectInteractorOutput, UserListOutput {
    weak var view: CreateDirectViewInput?

    var interactor: CreateDirectInteractorInput!
    var router: CreateDirectRouterInput!
    
    var userListInput: UserListInput!
    var userListUsers: [User]?
    
    required init(view: CreateDirectViewInput) { self.view = view }
    
    // MARK: - UserListOutput
    func didSelectUser(with index: Int) {
        guard let users = userListUsers else { return }
        
        view?.showHUD(with: "Creating...")
        interactor.createDirect(with: users[index])
    }

    // MARK: - CreateDirectViewOutput
    // MARK: - User
    func didEdit(user: User) {
        guard view != nil else { return }

        if let index = userListUsers?.firstIndex (where: { $0.imID == user.imID }) {
            userListUsers?[index] = user
            userListInput.updateList(with: userListUsers!.map { buildUserListCellModel(with: $0) })
        }
    }
    
    override func viewDidLoad() {
        setupUserList()
        interactor.requestUsers()
    }
    
    override func viewWillAppear() { interactor.setupDelegates() }
    
    func channelButtonPressed() {
        router.showCreateChatStory(of: .channel, with: userListUsers ?? [])
    }
    
    func groupChatButtonPressed() {
        router.showCreateChatStory(of: .chat, with: userListUsers ?? [])
    }
    
    // MARK: - CreateDirectInteractorOutput
    func conversationCreated(conversation model: Conversation) {
        view?.hideHUD()
        router.showConversationScreen(with: model)
    }
    
    func failedToCreateConversation(with error: Error) {
        view?.hideHUD()
        view?.showError(with: error.localizedDescription)
    }
    
    func usersLoaded(_ userArray: [User]) {
        userListUsers = userArray
        if let indexOfMe = userListUsers!.firstIndex(where: { $0.imID == interactor.me.imID })
        { userListUsers!.remove(at: indexOfMe) }
    
        userListInput.updateList(with: userListUsers!.map { buildUserListCellModel(with: $0) })
    }
    
    func usersLoadingFailed(with error: String) {
        view?.showError(with: error)
    }
    
    override func connectionLost() { view?.showError(with: "Cant connect") }
    
    override func tryingToLogin() { view?.showHUD(with: "Connecting...") }
    
    override func loginCompleted() { view?.hideHUD() }

    // MARK: - Private
    private func setupUserList() {
        guard let view = view else { return }
        view.userListView.presenter.userListOutput = self // TODO: - refactor
        userListInput = view.userListView.presenter
        view.userListView.presenter.type = .singlePick
    }
    
    private func buildUserListCellModel(with user: User) -> UserListCellModel {
        return UserListCellModel(displayName: user.displayName, pictureName: user.pictureName, isChoosen: false)
    }
}
