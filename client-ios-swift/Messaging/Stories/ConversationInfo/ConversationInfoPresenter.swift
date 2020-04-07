/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

final class ConversationInfoPresenter: Presenter, ConversationInfoViewOutput, ConversationInfoInteractorOutput, ConversationInfoRouterOutput, UserListOutput {
    weak var view: ConversationInfoViewInput?
    
    var interactor: ConversationInfoInteractorInput!
    var router: ConversationInfoRouterInput!
    var userListInput: UserListInput!
    
    private var conversation: Conversation
    private var type: ConversationType {
        return conversation.type
    }
    
    private var meIsAdmin: Bool? {
        return conversation.participants.first(where: { $0.user.imID == interactor.me?.imID })?.isOwner
    }
    
    required init(view: ConversationInfoViewInput, conversation: Conversation) {
        self.view = view
        self.conversation = conversation
    }
    
    // MARK: - UserListOutput -
    func didUpdateList(with modelArray: [UserListCellModel]) {
        view?.changeNumberOfMembers(with: modelArray.count)
    }
    
    // MARK: - ConversationInfoViewOutput -
    override func viewDidLoad() {
        guard let view = view else { return }
        
        setupUserList()
        let userCellArray = conversation.participants.map {
            buildUserListCellModel(with: $0.user)
        }
        view.changeNumberOfMembers(with: userCellArray.count)
        userListInput?.updateList(with: userCellArray)
        setupAppearance(for: conversation)
        view.showPermissions(type == .chat)
        view.showUserList(type != .direct)
    }

    override func viewWillAppear() {
        interactor.viewWillAppear()
    }
    
    override func viewDidAppear() {
        router.viewDidAppear()
    }
    
    func addMembersButtonPressed() {
        router.showAddParticipantsScreen(with: conversation)
    }
    
    func administratorsButtonPressed() {
        router.showAdminsScreen(with: conversation)
    }
    
    func permissionsButtonPressed() {
        router.showPermissionsScreen(with: conversation)
    }
    
    func membersButtonPressed() {
        router.showMembersScreen(with: conversation)
    }
    
    func leaveButtonPressed() {
        view?.showHUD(with: "Leaving...")
        interactor.leaveConversation(conversation)
    }
        
    func rightBarButtonPressed(with sender: BarButtonItem) {
        guard let view = view else { return }
        guard let title = view.profileHeader.title,
            !title.isEmpty else {
                view.showError(with: "Must enter title")
                return
        }
        
        if sender.buttonAction == .save && conversationHasChanged(conversation) {
            view.showHUD(with: "Updating...")
            interactor.editConversation(conversation, with: title,
                                        view.profileHeader.descriptionText, view.profileHeader.pictureName, isPublic: view.profileHeader.isPublic)
        }
        view.toggleEditView()
    }
    
    func didAppearAfterAdding(with conversation: Conversation) {
        self.conversation = conversation
        userListInput.updateList(with: conversation.participants.map { buildUserListCellModel(with: $0.user) })
    }
    
    func didAppearAfterRemoving(with conversation: Conversation) {
        self.conversation = conversation
        userListInput.updateList(with: conversation.participants.map { buildUserListCellModel(with: $0.user) })
    }
    
    func didAppearAfterChangingPermissions(_ conversation: Conversation) {
        self.conversation = conversation
    }
    
    // MARK: - ConversationInfoInteractorOutput -
    // MARK: - Conversation
    func isConversationUUIDEqual(to UUID: String) -> Bool {
        return conversation.uuid == UUID
    }
    
    func didUpdate(conversation: Conversation) {
        guard let view = view else { return }
        
        if !conversation.participants
            .contains(where: { $0.user.imID == interactor.me?.imID }) {
            view.showError(with: "You have been removed from the conversation")
            router.showConversationsScreen(with: conversation)
        } else {
            self.conversation = conversation
            let userCellArray = conversation.participants.map { buildUserListCellModel(with: $0.user) }
            
            view.changeNumberOfMembers(with: userCellArray.count)
            userListInput?.updateList(with: userCellArray)
            setupAppearance(for: conversation)
            view.hideHUD()
        }
    }
    
    func didRemove(conversation: Conversation) {
        guard let view = view else { return }
        
        view.showError(with: "Conversation was removed")
        router.showConversationsScreen(with: conversation)
    }
    
    func readEventReceived(with sequence: Int) {
        conversation.latestReadSequence = sequence
    }
    
    func didLeaveConversation() {
        view?.hideHUD()
        router.showConversationsScreen(with: conversation)
    }
    
    func failedToLeaveConversation(with error: Error) {
        view?.hideHUD()
        view?.showError(with: error.localizedDescription)
    }
    
    func failedToRequestConversation(with error: Error) {
        view?.showError(with: error.localizedDescription)
    }
    
    func failedToEditConversation(with error: Error) {
        view?.hideHUD()
        if error as NSError != VoxDemoError.errorNoChanges() {
            view?.showError(with: error.localizedDescription)
        }
    }
    
    func messageEventReceived() {
        conversation.lastSequence += 1
    }
    
    // MARK: - User
    func didEdit(user: User) {
        guard view != nil else { return }
        
        if var participant = conversation.participants.first(where: { $0.user.imID == user.imID }) {
            participant.user = user
            let userCellArray = conversation.participants.map { buildUserListCellModel(with: $0.user) }
            userListInput?.updateList(with: userCellArray)
        }
    }
    
    // MARK: - Connection
    override func connectionLost() {
        view?.showError(with: "Cant connect")
    }
    
    override func tryingToLogin() {
        view?.showHUD(with: "Connecting...")
    }
    
    override func loginCompleted() {
        view?.showHUD(with: "Updating...")
        interactor.requestConversation(for: conversation)
    }
    
    override func loginFailed(with error: Error) {
        view?.showError(with: "Login failed")
    }
    
    // MARK: - ConversationInfoRouterOutput -
    func requestConversation() -> Conversation {
        return conversation
    }
    
    // MARK: - Private Methods -
    private func setupUserList() {
        guard let view = view else { return }
        
        view.userListView.presenter.userListOutput = self
        userListInput = view.userListView.presenter
        view.userListView.presenter.type = .singlePick
    }
    
    private func setupAppearance(for conversation: Conversation) {
        guard let view = view else { return }
        
        switch conversation.type {
        case .direct:
            let userProfileModel = UserProfileModel(name: buildTitle(for: conversation),
                                                    pictureName: buildPictureName(for: conversation),
                                                    status: buildDescription(for: conversation))
            view.profileHeader.type = .user(model: userProfileModel)
            view.showEditButton(false)
            view.showLeaveButton(false)
            
        case .chat:
            let groupChatProfileModel = GroupChatProfileModel(title: buildTitle(for: conversation),
                                                              pictureName: buildPictureName(for: conversation),
                                                              description: buildDescription(for: conversation),
                                                              isUber: conversation.isUber, isPublic: conversation.isPublic)
            view.profileHeader.type = .groupChat(model: groupChatProfileModel)
            view.showEditButton(meIsAdmin ?? false)
            view.showLeaveButton(true)

        case .channel:
            let channelProfileModel = ChannelProfileModel(title: buildTitle(for: conversation),
                                                          pictureName: buildPictureName(for: conversation),
                                                          description: buildDescription(for: conversation))
            view.profileHeader.type = .channel(model: channelProfileModel)
            view.showEditButton(meIsAdmin ?? false)
            view.showLeaveButton(true)
        }
    }
    
    private func buildUserListCellModel(with user: User) -> UserListCellModel {
        return UserListCellModel(displayName: user.displayName, pictureName: user.pictureName, isChoosen: false)
    }
    
    private func buildTitle(for conversation: Conversation) -> String {
        if conversation.type == .direct
        {
            var displayName: String = ""
            conversation.participants.forEach
                { participant in
                    if participant.user.imID != interactor.me!.imID // ! is because at this moment we already logged in and me should be available
                    { displayName = participant.user.displayName }
                }
            return displayName
        }
        else { return conversation.title }
    }
    
    private func buildDescription(for conversation: Conversation) -> String? {
        if conversation.type == .direct
        {
            var description: String?
            conversation.participants.forEach
                { participant in
                    if participant.user.imID != interactor.me!.imID // ! is because at this moment we already logged in and me should be available
                    { description = participant.user.status }
                }
            return description
        }
        else { return conversation.description }
    }
    
    private func buildPictureName(for conversation: Conversation) -> String? {
        if conversation.type == .direct
        {
            var pictureName: String?
            conversation.participants.forEach
                { participant in
                    if participant.user.imID != interactor.me!.imID // ! is because at this moment we already logged in and me should be available
                    { pictureName = participant.user.pictureName }
                }
            return pictureName
        }
        else { return conversation.pictureName }
    }
    
    private func conversationHasChanged(_ conversation: Conversation) -> Bool {
        return
            !(conversation.title == view?.profileHeader.title
                && conversation.description == view?.profileHeader.descriptionText
                && conversation.pictureName == view?.profileHeader.pictureName
                && conversation.isPublic == view?.profileHeader.isPublic)
    }
    
}
