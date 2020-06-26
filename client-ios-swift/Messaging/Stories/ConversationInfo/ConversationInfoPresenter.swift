/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

final class ConversationInfoPresenter:
    ControllerLifeCycleObserver,
    ConversationInfoViewOutput,
    ConversationInfoInteractorOutput,
    UserListOutput,
    MainQueuePerformable
{
    private weak var view: ConversationInfoViewInput?
    var interactor: ConversationInfoInteractorInput! // DI
    var router: ConversationInfoRouterInput! // DI
    weak var userListInput: UserListInput! // DI
    
    private var conversation: Conversation { interactor.activeConversation }
    private var type: Conversation.ConversationType { conversation.type }
    var numberOfUsers: Int { interactor.numberOfParticipants }
    private var meIsAdmin: Bool? {
        conversation.participants.first(where: { $0.user.me })?.isOwner
    }
    private var editingAllowed: Bool {
        type != .direct && meIsAdmin ?? false
    }
    private var appearedMoreThanOnce: Bool = false
    private var onTheScreen = false
    
    var previousState: ConversationInfoViewControllerState?
    
    init(view: ConversationInfoViewInput) { self.view = view }
    
    // MARK: - UserListOutput -
    func getUser(at indexPath: IndexPath) -> User {
        interactor.getParticipant(at: indexPath.row).user
    }
    
    // MARK: - ConversationInfoViewOutput -
    func viewDidLoad() {
        userListInput.type = .singlePick
        
        switch conversation.type {
        case .direct:
            view?.profileHeader.setState(.initial(type: .user))
            view?.showLeaveButton(false)
        case .chat:
            view?.profileHeader.setState(.initial(type: .groupChat))
            view?.showLeaveButton(true)
        case .channel:
            view?.profileHeader.setState(.initial(type: .channel))
            view?.showLeaveButton(true)
        }
        
        refreshUI(includingParticipants: false)
        
        interactor.setupObservers()
    }
    
    func viewDidAppear() {
        if appearedMoreThanOnce {
            refreshUI(includingParticipants: true, changeState: false)
        }
        onTheScreen = true
    }
    
    func viewWillDisappear() {
        appearedMoreThanOnce = true
        onTheScreen = false
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
                view.showError("Must enter title")
                return
        }
        
        if sender.buttonAction == .save && conversationHasChanged(conversation) {
            view.showHUD(with: "Updating...")
            interactor.editConversation(
                conversation, with: title,
                view.profileHeader.descriptionText,
                view.profileHeader.pictureName,
                isPublic: view.profileHeader.isPublic
            )
        } else {
            refreshUI(includingParticipants: false, changeState: true)
        }
    }
    
    // MARK: - ConversationInfoInteractorOutput -
    func conversationDisappeared() {
        onMainQueue {
            self.view?.hideHUD()
            self.router.showConversationsScreen()
        }
    }
    
    func conversationChanged(participantsChanged: Bool) {
        onMainQueue {
            if self.onTheScreen {
                self.refreshUI(includingParticipants: participantsChanged)
            }
        }
    }
    
    func failedToLeaveConversation(with error: Error) {
        onMainQueue {
            self.view?.hideHUD()
            self.view?.showError(error)
        }
    }
    
    func failedToEditConversation(with error: Error) {
        onMainQueue {
            self.view?.hideHUD()
            self.view?.showError(error)
        }
    }

    // MARK: - Private Methods -
    private func refreshUI(includingParticipants: Bool, changeState: Bool = false) {
        view?.hideHUD()
        
        view?.profileHeader.setModel(ProfileInfoView.ProfileInfoViewModel(
            title: conversation.title,
            pictureName: conversation.pictureName,
            description: conversation.description,
            isUber: conversation.isUber,
            isPublic: conversation.isPublic)
        )
        
        if let oldState = previousState {
            switch oldState {
            case .editing(let showPermissions):
                view?.state = changeState
                    ? .normal(editingAllowed: editingAllowed,
                              numberOfMembers: numberOfUsers,
                              showMembers: type != .direct)
                    : .editing(showPermissions: showPermissions)
            case .normal(_, _, _):
                view?.state = changeState
                    ? .editing(showPermissions: type == .chat)
                    : .normal(editingAllowed: editingAllowed,
                              numberOfMembers: numberOfUsers,
                              showMembers: type != .direct)
            }
        } else {
            view?.state = .normal(
                editingAllowed: editingAllowed,
                numberOfMembers: numberOfUsers,
                showMembers: type != .direct
            )
        }
        previousState = view?.state
        
        if includingParticipants {
            userListInput.refresh()
        }
    }
    
    private func conversationHasChanged(_ conversation: Conversation) -> Bool {
        !(conversation.title == view?.profileHeader.title
            && conversation.description == view?.profileHeader.descriptionText ?? ""
            && conversation.pictureName == view?.profileHeader.pictureName
            && conversation.isPublic == view?.profileHeader.isPublic)
    }
}
