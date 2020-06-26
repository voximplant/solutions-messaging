/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

final class AddParticipantsPresenter:
    ControllerLifeCycleObserver,
    AddParticipantsViewOutput,
    AddParticipantsInteractorOutput,
    UserListOutput,
    MainQueuePerformable
{
    private weak var view: AddParticipantsViewInput?
    var interactor: AddParticipantsInteractorInput! // DI
    var router: AddParticipantsRouterInput! // DI
    weak var userListInput: UserListInput! // DI
    
    private var appearedMoreThanOnce: Bool = false
    private let type: AddParticipantsModuleType
    private var selectedUsers: Set<User.ID> { userListInput.selectedUserIDs }
    var numberOfUsers: Int {
        type == .members
            ? interactor.numberOfParticipants
            : interactor.numberOfAdmins
    }
    
    init(view: AddParticipantsViewInput, type: AddParticipantsModuleType) {
        self.view = view
        self.type = type
    }
    
    // MARK: - UserListOutput
    func didSelectUser(at index: Int) {
        view?.allowAdding(selectedUsers.count > 0)
    }
    
    func getUser(at indexPath: IndexPath) -> User {
        type == .members
            ? interactor.getParticipant(at: indexPath.row)
            : interactor.getAdmin(at: indexPath.row).user
    }
        
    // MARK: - AddParticipantsViewOutput
    func viewDidLoad() {
        userListInput.type = .multiplePick
        view?.title = "Add \(type == .members ? "Members" : "Administrators")"
    }
    
    func viewWillAppear() {
        interactor.setupObservers()
        if appearedMoreThanOnce {
            userListInput.refresh()
        }
    }
    
    func viewWillDisappear() {
        interactor.removeObservers()
        appearedMoreThanOnce = true
    }
    
    func addButtonPressed() {
        guard !selectedUsers.isEmpty else { return }
        view?.showHUD(with: "Adding...")
        type == .members
            ? interactor.addUsers(selectedUsers)
            : interactor.addAdmins(selectedUsers)
    }
        
    // MARK: - AddParticipantsInteractorOutput
    func conversationDisappeared() {
        onMainQueue {
            self.view?.hideHUD()
            self.router.showConversationsScreen()
        }
    }
    
    func conversationChanged(participantsChanged: Bool) {
        onMainQueue {
            self.view?.hideHUD()
            self.userListInput.cleanSelectedUsers()
            self.view?.allowAdding(self.selectedUsers.count > 0)
            if participantsChanged {
                self.userListInput.refresh()
            }
        }
    }
    
    func failedToAddUsers(with error: Error) {
        onMainQueue {
            self.view?.hideHUD()
            self.view?.showError("Could'nt add users - \(error.localizedDescription)")
        }
    }
    
    func failedToAddAdmins(with error: Error) {
        onMainQueue {
            self.view?.hideHUD()
            self.view?.showError("Could'nt add admins - \(error.localizedDescription)")
        }
    }
}

enum AddParticipantsModuleType {
    case members
    case admins
}
