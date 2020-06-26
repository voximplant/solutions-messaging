/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

final class PermissionsPresenter:
    ControllerLifeCycleObserver,
    PermissionsViewOutput,
    PermissionsInteractorOutput,
    MainQueuePerformable
{
    private weak var view: PermissionsViewInput?
    var interactor: PermissionsInteractorInput! // DI
    var router: PermissionsRouterInput! // DI
    
    private var permissions: Permissions { interactor.permissions }
    
    init(view: PermissionsViewInput) { self.view = view }

    // MARK: - PermissionsViewOutput
    func viewDidLoad() {
        updateView(with: permissions)
    }
    
    func viewWillAppear() {
        interactor.setupObservers()
    }
    
    func viewWillDisappear() {
        interactor.removeObservers()
    }
    
    func permissionsChanged() {
        view?.showSaveButton(isPermissionsChanged)
    }
    
    func barButtonPressed() {
        guard let newPermissions = editedPermissions, isPermissionsChanged else { return }
        view?.showHUD(with: "Saving...")
        view?.showSaveButton(false)
        interactor.editPermissions(newPermissions)
    }
    
    // MARK: - PermissionsInteractorOutput
    func permissionsChanged(_ permissions: Permissions) {
        onMainQueue {
            self.view?.hideHUD()
            self.updateView(with: permissions)
        }
    }
    
    func conversationDisappeared() {
        onMainQueue {
            self.view?.hideHUD()
            self.router.showConversationsScreen()
        }
    }
    
    func failedToEditPermissions(with error: Error) {
        onMainQueue {
            self.updateView(with: self.permissions)
            self.view?.hideHUD()
            self.view?.showError(error)
        }
    }
    
    // MARK: - Private
    private var editedPermissions: Permissions? {
        guard let view = view else { return nil }
        return Permissions(
            canWrite: view.canWrite,
            canEditMessages: view.canEdit,
            canEditAllMessages: view.canEditAll,
            canRemoveMessages: view.canRemove,
            canRemoveAllMessages: view.canRemoveAll,
            canManageParticipants: view.canManage
        )
    }
    
    private var isPermissionsChanged: Bool {
        editedPermissions != permissions
    }
    
    private func updateView(with permissions: Permissions) {
        view?.canWrite = permissions.canWrite
        view?.canEdit = permissions.canEditMessages
        view?.canEditAll = permissions.canEditAllMessages
        view?.canRemove = permissions.canRemoveMessages
        view?.canRemoveAll = permissions.canRemoveAllMessages
        view?.canManage = permissions.canManageParticipants
    }
}
