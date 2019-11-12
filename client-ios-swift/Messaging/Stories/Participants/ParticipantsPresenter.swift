/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation
 
enum ParticipantsModuleType {
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

class ParticipantsPresenter: Presenter, ParticipantsViewOutput, ParticipantsInteractorOutput, ParticipantsRouterOutput, UserListOutput {
    weak var view: ParticipantsViewInput?
    
    var interactor: ParticipantsInteractorInput!
    var router: ParticipantsRouterInput!
    var userListInput: UserListInput!
    
    private var type: ParticipantsModuleType
    private var userArray: [User] = []
    
    init(view: ParticipantsViewInput, type: ParticipantsModuleType) {
        self.view = view
        self.type = type
    }
    
    func didAppearAfterAdding(with conversation: Conversation) {
        type.conversation = conversation
        if case .members = type {
            userArray = conversation.participants.map { $0.user }
            userListInput.updateList(with: userArray.map { buildUserCellModel(from: $0) })
        }
        else if case .admins = type {
            userArray = conversation.participants.filter { $0.isOwner && $0.user.imID != interactor.me.imID }.map { $0.user }
            userListInput.updateList(with: userArray.map { buildUserCellModel(from: $0) })
        }
    }
    
    // MARK: - UserListOutput -
    func didRemoveUser(with index: Int) {
        guard let view = view else { return }
        
        view.showHUD(with: "Removing...")
        if case .admins = type {
            interactor.remove(admin: userArray[index], conversation: type.conversation)
        }
        else if case .members = type {
            interactor.remove(member: userArray[index], conversation: type.conversation)
        }
        userArray.remove(at: index)
        userListInput.updateList(with: userArray.map { buildUserCellModel(from: $0) })
    }
    
    // MARK: - ParticipantsViewOutput
    override func viewDidLoad() {
        setupUserList()
        setupType()
    }
    
    override func viewWillAppear() {
        interactor.viewWillAppear()
    }
    
    override func viewDidAppear() {
        router.viewDidAppear()
    }
    
    func addMemberButtonPressed() {
        switch type {
        case .members(model: _): router.showAddParticipantsScreen(with: type.conversation)
        case .admins(model: _): router.showAddAdminsScreen(with: type.conversation)
        }
    }
    
    // MARK: - ParticipantsInteractorOutput -
    // MARK: - Conversation
    func isConversationUUIDEqual(to UUID: String) -> Bool {
        return type.conversation.uuid == UUID
    }
    
    func didUpdate(conversation: Conversation) {
        guard let view = view else { return }
        
        if !conversation.participants
            .contains { $0.user.imID == interactor.me.imID } {
            view.showError(with: "You have been removed from the conversation")
            router.showConversationsScreen(with: conversation)
        } else {
            self.type.conversation = conversation
            if case .admins = type { fetchAdmins(in: conversation) }
            else if case .members = type {
                let userCellArray = type.conversation.participants
                    .filter { $0.user.imID != interactor.me.imID }
                    .map { buildUserCellModel(from: $0.user) }
                userListInput?.updateList(with: userCellArray)
            }
        }
        view.hideHUD()
    }
    
    func didRemove(conversation: Conversation) {
        guard let view = view else { return }
        
        view.showError(with: "Conversation was removed")
        router.showConversationsScreen(with: conversation)
    }
    
    func failedToRequestConversation(with error: Error) {
        view?.showError(with: error.localizedDescription)
    }
    
    func didRemove(participant: User) {
        view?.hideHUD()
        type.conversation.participants.removeAll { $0.user.imID == participant.imID }
    }
    
    func failedToRemove(participant: User, _ error: Error) {
        guard let view = view else { return }
        
        userArray.append(participant)
        userListInput.updateList(with: userArray.map { buildUserCellModel(from: $0) })
        view.hideHUD()
        view.showError(with: "failed to remove \(participant.displayName). \(error.localizedDescription)")
    }
    
    func didRemove(admin: User) {
        guard let view = view else { return }
        
        view.hideHUD()
        if let index = type.conversation.participants.firstIndex(where: { $0.user.imID == admin.imID }),
            let permissions = type.conversation.permissions {
            type.conversation.participants[index].isOwner = false
            type.conversation.participants[index].permissions = permissions
        }
    }
    
    func failedToRemove(admin: User, with error: Error) {
        guard let view = view else { return }
        
        userArray.append(admin)
        userListInput.updateList(with: userArray.map { buildUserCellModel(from: $0) })
        view.hideHUD()
        view.showError(with: "failed to remove \(admin.displayName). \(error.localizedDescription)")
    }
    
    func readEventReceived(with sequence: Int) {
        type.conversation.latestReadSequence = sequence
    }
    
    func messageEventReceived() {
        type.conversation.lastSequence += 1
    }
    
    // MARK: - User
    func didEdit(user: User) {
        guard view != nil else { return }
        
        if var participant = type.conversation.participants.first(where: { $0.user.imID == user.imID }) {
            participant.user = user
            let userCellArray = type.conversation.participants.map { buildUserCellModel(from: $0.user) }
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
        interactor.requestConversation(for: type.conversation)
    }
    
    override func loginFailed(with error: Error) {
        view?.showError(with: "Login failed")
    }
    
    // MARK: - ParticipantsRouterOutput -
    func requestConversationModel() -> Conversation {
        return type.conversation
    }
    
    // MARK: - Private Methods -
    private func setupType() {
        switch type {
        case .members(model: let conversation):
            fetchMembers(in: conversation)
        case .admins(model: let conversation):
            fetchAdmins(in: conversation)
        }
        view?.updateAppearance(with: type.title)
    }
    
    private func fetchAdmins(in conversation: Conversation) {
        userArray.removeAll()
        var cellModelArray: [UserListCellModel] = []
        conversation.participants.forEach { participant in
            if participant.user.imID != interactor.me.imID && participant.isOwner
            {
                userArray.append(participant.user)
                cellModelArray.append(buildUserCellModel(from: participant.user))
            }
        }
        userListInput.updateList(with: cellModelArray)
    }
    
    private func fetchMembers(in conversation: Conversation) {
        userArray.removeAll()
        var cellModelArray: [UserListCellModel] = []
        conversation.participants.forEach { participant in
            if participant.user.imID != interactor.me.imID
            {
                userArray.append(participant.user)
                cellModelArray.append(buildUserCellModel(from: participant.user))
            }
        }
        userListInput.updateList(with: cellModelArray)
    }
    
    private func setupUserList() {
        guard let view = view else { return }
        view.userListView.presenter.userListOutput = self
        userListInput = view.userListView.presenter
        view.userListView.presenter.type = .editable
    }
    
    private func buildUserCellModel(from userModel: User) -> UserListCellModel {
        return UserListCellModel(displayName: userModel.displayName, pictureName: userModel.pictureName, isChoosen: false)
    }
}
