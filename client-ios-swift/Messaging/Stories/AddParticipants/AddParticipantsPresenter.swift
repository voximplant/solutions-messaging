/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

enum AddParticipantsModuleType {
    case members (model: Conversation)
    case admins  (model: Conversation)
    
    var conversation: Conversation {
        get {
            switch self {
            case .members(let model): return model
            case .admins(let model): return model
            }
        }
        set {
            switch self {
            case .members: self = .members(model: newValue)
            case .admins: self = .admins(model: newValue)
            }
        }
    }
    
    var title: String {
        switch self {
        case .members(model: _): return "Members"
        case .admins(model: _): return "Administrators"
        }
    }
}

final class AddParticipantsPresenter: Presenter, AddParticipantsViewOutput, AddParticipantsInteractorOutput, AddParticipantsRouterOutput, UserListOutput {
    private var type: AddParticipantsModuleType
    private weak var view: AddParticipantsViewInput?
    
    var interactor: AddParticipantsInteractorInput!
    var router: AddParticipantsRouterInput!
    
    var userListInput: UserListInput!
    private var userListUsers: [User]?
    
    required init(view: AddParticipantsViewInput, type: AddParticipantsModuleType) {
        self.view = view
        self.type = type
    }
    
    // MARK: - UserListOutput
    func didSelectUser(with index: Int) {
        print(userListInput.userListModelArray)
        view?.enableAddButton(userListInput.userListModelArray.contains(where: { $0.isChoosen }))
    }
    
    // MARK: - AddParticipantsInteractorOutput
    override func viewDidLoad() {
        setupUserListProtocols()
        setupType()
        view?.updateTitle(with: "Add \(type.title)")
    }
    
    override func viewWillAppear() {
        interactor.setupDelegates()
    }
    
    override func viewDidAppear() {
        router.viewDidAppear()
    }
    
    func addButtonPressed() {
        guard let selectedUsers = buildSelectedModelArray() else { return }
        view?.showHUD(with: "Adding...")
        switch type {
        case .members(model: let conversation):
            interactor.addUsers(selectedUsers, to: conversation)
        case .admins(model: let conversation):
            interactor.addAdmins(selectedUsers, in: conversation)
        }
    }
    
    // MARK: - AddParticipantsInteractorOutput
    // MARK: - Conversation
    func didEdit(conversation: Conversation) {
        guard let view = view else { return }
        
        if !conversation.participants
            .contains { $0.user.imID == interactor.me?.imID } {
            view.showError(with: "You have been removed from the conversation")
            router.showConversationsScreen(with: conversation)
        } else {
            self.type.conversation = conversation
            if case .admins = type {
                userListUsers = filterAdminsArray()
                let cellModels = userListUsers!.map { buildUserListCellModel(with: $0) }
                userListInput.updateList(with: cellModels)
            }
            else if case .members = type {
                let userCellArray = type.conversation.participants
                    .filter { $0.user.imID != interactor.me!.imID }
                    .map { buildUserListCellModel(with: $0.user) }
                userListInput?.updateList(with: userCellArray)
            }
        }
    }
    
    func didRemove(conversation: Conversation) {
        guard let view = view else { return }
        
        view.showError(with: "Conversation was removed")
        router.showConversationsScreen(with: conversation)
    }
    
    func readEventReceived(with sequence: Int) {
        type.conversation.latestReadSequence = sequence
    }
    
    // MARK: - User
    func didEdit(user: User) {
        guard view != nil else { return }
        
        if var participant = type.conversation.participants.first(where: { $0.user.imID == user.imID }) {
            participant.user = user
            let userCellArray = type.conversation.participants.map { buildUserListCellModel(with: $0.user) }
            userListInput?.updateList(with: userCellArray)
        }
    }
    
    func didLoadUsers(_ users: [User]) {
        userListUsers = filterUserArray(with: users)
        if userListUsers!.isEmpty { return }
        let userListCellArray = userListUsers!.map { buildUserListCellModel(with: $0) }
        userListInput.updateList(with: userListCellArray)
    }
    
    func failedToLoadUsers(with error: Error) {
        view?.showError(with: "Could'nt update users - \(error.localizedDescription)")
    }
    
    func didAddUsers(to conversation: Conversation) {
        type.conversation = conversation
        conversation.participants.forEach { participant in
            userListUsers?.removeAll(where: { participant.user.imID == $0.imID })
        }
        userListInput.updateList(with: userListUsers!.map { buildUserListCellModel(with: $0) })
        view?.hideHUD()
        view?.enableAddButton(false)
    }
    
    func failedToAddUsers(with error: Error) {
        view?.hideHUD()
        view?.showError(with: "Could'nt add users - \(error.localizedDescription)")
    }
    
    func didAddAdmins(_ adminArray: [User]) {
        for user in adminArray {
            if let index = type.conversation.participants.firstIndex(where: { $0.user.imID == user.imID }) {
                type.conversation.participants[index].isOwner = true
                type.conversation.participants[index].permissions = Permissions.defaultForAdmin()
            }
        }
        adminArray.forEach { user in userListUsers?.removeAll { $0.imID == user.imID } }
        userListInput.updateList(with: userListUsers!.map { buildUserListCellModel(with: $0) })
        view?.hideHUD()
        view?.enableAddButton(false)
    }
    
    func failedToAddAdmins(with error: Error) {
        view?.hideHUD()
        view?.showError(with: "Could'nt add admins - \(error.localizedDescription)")
    }
    
    func didReceiveConversation(with model: Conversation) {
        type.conversation = model
        if case .admins = type { prepareAdminsData() }
    }
    
    func failedToRequestConversation(with error: Error) {
        view?.showError(with: error.localizedDescription)
    }
    
    func isConversationUUIDEqual(to UUID: String) -> Bool {
        return type.conversation.uuid == UUID
    }
    
    func messageEventReceived() {
        type.conversation.lastSequence += 1
    }
    
    override func connectionLost() { view?.showHUD(with: "Connecting...") }
    
    override func tryingToLogin() {
        view?.showHUD(with: "Connecting...")
    }
    
    override func loginCompleted() {
        view?.hideHUD()
    }
    
    // MARK: - AddParticipantsRouterOutput
    func requestConversationModel() -> Conversation { return type.conversation }
    
    // MARK: - Private
    private func setupUserListProtocols() {
        guard let view = view else { return }
        view.userList.presenter.userListOutput = self // TODO: - refactor
        userListInput = view.userList.presenter
        view.userList.presenter.type = .multiplePick
    }
    
    private func setupType() {
        switch type {
        case .members(model: _): interactor.requestUsers()
        case .admins(model: _): prepareAdminsData()
        }
    }
    
    private func prepareAdminsData() {
        userListUsers = filterAdminsArray()
        let cellModels = userListUsers!.map { buildUserListCellModel(with: $0) }
        userListInput.updateList(with: cellModels)
    }
    
    private func filterUserArray(with fullUserArray: [User]) -> [User] {
        var finalArray: [User] = fullUserArray
        
        type.conversation.participants.forEach { participant in
            finalArray.removeAll { $0.imID == participant.user.imID }
        }
        return finalArray
    }
    
    private func filterAdminsArray() -> [User] {
        var participants = type.conversation.participants
        participants.removeAll { $0.isOwner == true }
        return participants.map { $0.user }
    }
    
    private func buildUserListCellModel(with user: User) -> UserListCellModel {
        return UserListCellModel(displayName: user.displayName, pictureName: user.pictureName, isChoosen: false)
    }
    
    private func buildSelectedModelArray() -> [User]? {
        guard let selectedUsers = userListInput?.userListModelArray,
            let userModels = userListUsers
            else { return nil }
        
        var selectedModels: [User] = []
        for (index, user) in selectedUsers.enumerated() {
            if user.isChoosen
            { selectedModels.append(userModels[index]) }
        }
        return selectedModels
    }
}
