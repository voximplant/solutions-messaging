/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

final class CreateChatPresenter: Presenter, CreateChatViewOutput, CreateChatInteractorOutput, UserListOutput {
    weak var view: CreateChatViewInput?
    var userListInput: UserListInput!
    
    var interactor: CreateChatInteractorInput!
    var router: CreateChatRouterInput!
    var type: ConversationType!
    var userListUsers: [User]
    
    required init(view: CreateChatViewInput, users: [User]) {
        self.view = view
        self.userListUsers = users
    }
    
    // MARK: - CreateChatViewOutput
    func createChatPressed() {
        guard let view = view else { return }
        guard let userArray = buildSelectedModelArray() else { return }
        guard let name = view.conversationInfoView.title,
            !name.isEmpty else {
                view.showError(with: "Must enter title")
                return
        }
        
        let imageName = view.conversationInfoView.profileImageView.name
        let description = view.conversationInfoView.descriptionText ?? ""
        
        view.userInteraction(allowed: false)
        if type == .chat {
            guard let isPublic = view.conversationInfoView.isPublic else { fatalError() }
            guard let isUber = view.conversationInfoView.isUber else { fatalError() }
            view.showHUD(with: "Creating...")
            interactor.createConversation(with: name, and: userArray, imageName: imageName,
                                          description: description, isPublic: isPublic, isUber: isUber) }
        else if type == .channel {
            view.showHUD(with: "Creating...")
            interactor.createChannel(with: name, imageName: imageName,
                                     description: description, and: userArray) }
    }
    
    override func viewDidLoad() {
        setupUserList()
        if userListUsers.isEmpty {
            interactor.requestUsers()
        } else {
            if let indexOfMe = userListUsers.firstIndex(where: { $0.imID == interactor.me.imID })
            { userListUsers.remove(at: indexOfMe) }
            
            userListInput.updateList(with: userListUsers.map { buildUserListCellModel(with: $0) })
        }
        setupHeaderAppeareance(with: type)
    }
    
    override func viewWillAppear() { interactor.setupDelegates() }
    
    // MARK: - CreateChatInteractorOutput
    // MARK: - User
    func didEdit(user: User) {
        guard view != nil else { return }

        if let index = userListUsers.firstIndex (where: { $0.imID == user.imID }) {
            userListUsers[index] = user
            userListInput.updateList(with: userListUsers.map { buildUserListCellModel(with: $0) })
        }
    }
    
    func chatCreated(_ model: Conversation) {
        view?.hideHUD()
        router.showConversationScreen(with: model)
        view?.userInteraction(allowed: true)
    }
    
    func failedToCreateChat(with error: Error) {
        view?.hideHUD()
        view?.showError(with: error.localizedDescription)
        view?.userInteraction(allowed: true)
    }
    
    func usersLoaded(_ userArray: [User]) {
        userListUsers = userArray
        if let indexOfMe = userListUsers.firstIndex(where: { $0.imID == interactor.me.imID })
        { userListUsers.remove(at: indexOfMe) }
        
        userListInput.updateList(with: userListUsers.map { buildUserListCellModel(with: $0) })
    }
    
    func usersLoadingFailed(with error: Error) {
        view?.showError(with: error.localizedDescription)
    }
    
    override func connectionLost() { view?.showError(with: "Cant connect") }
    
    override func tryingToLogin() { view?.showHUD(with: "Connecting...") }
    
    override func loginCompleted() { view?.hideHUD() }
    
    // MARK: - Private methods
    private func setupHeaderAppeareance(with type: ConversationType) {
        guard let view = view else { return }
        view.setTitle(type == .chat ? "New Conversation" : "New Channel")
        view.conversationInfoView.type = type == .chat
            ? .groupChat(model: GroupChatProfileModel(title: "", pictureName: nil, description: nil, isUber: true, isPublic: false))
            : .channel(model: ChannelProfileModel(title: "", pictureName: nil, description: nil))
        view.conversationInfoView.isEditable = true
    }
    
    private func setupUserList() {
        guard let view = view else { return }
        view.userListView.presenter.userListOutput = self // TODO: - refactor
        userListInput = view.userListView.presenter
        view.userListView.presenter.type = .multiplePick
    }
    
    private func buildSelectedModelArray() -> [User]? {
        guard let selectedUsers = userListInput?.userListModels
            else { return nil }
        
        var selectedModels: [User] = []
        for (index, user) in selectedUsers.enumerated() {
            if user.isChoosen
            { selectedModels.append(userListUsers[index]) }
        }
        return selectedModels
    }
    
    private func buildUserListCellModel(with user: User) -> UserListCellModel {
        return UserListCellModel(displayName: user.displayName, pictureName: user.pictureName, isChoosen: false)
    }
    
}
