/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation
 
final class ParticipantsPresenter:
    ControllerLifeCycleObserver,
    ParticipantsViewOutput,
    ParticipantsInteractorOutput,
    UserListOutput,
    MainQueuePerformable
{
    private weak var view: ParticipantsViewInput?
    var interactor: ParticipantsInteractorInput! // DI
    var router: ParticipantsRouterInput! // DI
    weak var userListInput: UserListInput! // DI
    
    private var appearedMoreThanOnce: Bool = false
    private var onTheScreen = false
    private var type: ParticipantsModuleType
    var numberOfUsers: Int {
        type == .members
            ? interactor.numberOfParticipants
            : interactor.numberOfAdmins
    }
    
    init(view: ParticipantsViewInput, type: ParticipantsModuleType) {
        self.view = view
        self.type = type
    }
    
    // MARK: - UserListOutput -
    func didRemoveUser(at index: Int) {
        guard let view = view else { return }

        view.showHUD(with: "Removing...")
        if type == .members {
            interactor.remove(participant: interactor.getParticipant(at: index).user.id)
        }
        if type == .admins {
            interactor.remove(admin: interactor.getAdmin(at: index).user.id)
        }
    }
    
    func getUser(at indexPath: IndexPath) -> User {
        type == .members
            ? interactor.getParticipant(at: indexPath.row).user
            : interactor.getAdmin(at: indexPath.row).user
    }
    
    // MARK: - ParticipantsViewOutput
    func viewDidLoad() {
        interactor.setupObservers()
        userListInput.type = .editable
        view?.updateAppearance(with: type == .members ? "Members" : "Administrators")
    }
    
    func viewWillAppear() {
        if appearedMoreThanOnce {
            userListInput.refresh()
        }
        onTheScreen = true
    }
    
    func viewWillDisappear() {
        appearedMoreThanOnce = true
        onTheScreen = false
    }

    func addMember() {
        switch type {
        case .members:
            router.showAddParticipantsScreen(with: interactor.activeConversation)
        case .admins:
            router.showAddAdminsScreen(with: interactor.activeConversation)
        }
    }
    
    // MARK: - ParticipantsInteractorOutput -
    func conversationDisappeared() {
        onMainQueue {
            self.view?.hideHUD()
            self.router.showConversationsScreen()
        }
    }
    
    func conversationChanged(participantsChanged: Bool) {
        onMainQueue {
            self.view?.hideHUD()
            if participantsChanged && self.onTheScreen {
                self.userListInput.refresh()
            }
        }
    }
    
    func failedToRemove(with error: Error) {
        onMainQueue {
            self.view?.hideHUD()
            self.view?.showError("failed to remove. \(error.localizedDescription)")
        }
    }
}

enum ParticipantsModuleType {
    case members
    case admins
}
