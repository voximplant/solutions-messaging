/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

class PermissionsPresenter: Presenter, PermissionsViewOutput, PermissionsInteractorOutput, PermissionsRouterOutput, PermissionSwitchDelegate {
    weak var view: PermissionsViewInput?
    
    var interactor: PermissionsInteractorInput!
    var router: PermissionsRouterInput!
    
    private var conversation: Conversation
    private var editedPermissions: Permissions!
    
    private let dataSource: TableViewDataSource<PermissionsCellModel> = .make(with: [])
    private var cellModelArray: [PermissionsCellModel] {
        get { return dataSource.models }
        set { dataSource.models = newValue }
    }
    
    required init(view: PermissionsViewInput, conversation: Conversation) {
        self.view = view
        self.conversation = conversation
        editedPermissions = conversation.permissions
    }
    
    func isConversationUUIDEqual(to UUID: String) -> Bool {
        return conversation.uuid == UUID
    }
    
    // MARK: - PermissionsViewOutput
    override func viewDidLoad() {
        cellModelArray = conversation.permissions!.map { (key, value) in
            PermissionsCellModel(name: key, isAllowed: value, delegate: self)
        }
        cellModelArray.sort { $0.isAllowed && !$1.isAllowed }
        view?.setupTableView(with: dataSource)
    }
    
    override func viewWillAppear() {
        interactor.setupDelegates()
    }
    
    override func viewDidAppear() {
        router.viewDidAppear()
    }
    
    func barButtonPressed() {
        if editedPermissions == conversation.permissions { return }
        view?.showHUD(with: "Saving...")
        view?.showSaveButton(false)
        interactor.editPermissions(editedPermissions, in: conversation)
    }
    
    // MARK: - PermissionsInteractorOutput
    // MARK: - Conversation
    func didEdit(conversation: Conversation) {
        guard let view = view  else { return }
        
        if !conversation.participants
            .contains { $0.user.imID == interactor.me.imID } {
            view.showError(with: "You have been removed from the conversation")
            router.showConversationsScreen(with: conversation)
        } else {
            self.conversation = conversation
            cellModelArray = conversation.permissions!.map { (key, value) in
                PermissionsCellModel(name: key, isAllowed: value, delegate: self)
            }
            view.reloadUI()
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
    
    func messageEventReceived() {
        conversation.lastSequence += 1
    }
    
    // MARK: - User
    func didEdit(user: User) {
        guard view != nil else { return }
        
        if var participant = conversation.participants.first(where: { $0.user.imID == user.imID }) {
            participant.user = user
        }
    }
    
    func didEditPermissions(_ newPermissions: Permissions) {
        view?.hideHUD()
        conversation.permissions = newPermissions
        for index in 0 ..< conversation.participants.count {
            if !conversation.participants[index].isOwner {
                conversation.participants[index].permissions = newPermissions
            }
        }
    }
    
    func failedToEditPermissions(with error: Error) {
        cellModelArray = conversation.permissions!.map { (key, value) in
            PermissionsCellModel(name: key, isAllowed: value, delegate: self)
        }
        view?.reloadUI()
        view?.hideHUD()
        view?.showError(with: error.localizedDescription)
    }
    
    override func connectionLost() { view?.showError(with: "Cant connect") }
    
    override func tryingToLogin() { view?.showHUD(with: "Connecting...") }
    
    override func loginCompleted() { view?.hideHUD() }
    
    // MARK: - PermissionsRouterOutput
    func requestConversationModel() -> Conversation { return conversation }
    
    // MARK: - PermissionSwitchDelegate
    func didChangeSwitchValue(in model: PermissionsCellModel) {
        editedPermissions[model.name] = model.isAllowed
        if editedPermissions != conversation.permissions { view?.showSaveButton(true) }
    }
}
