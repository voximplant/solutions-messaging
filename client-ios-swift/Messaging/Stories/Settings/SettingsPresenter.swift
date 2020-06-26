/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

final class SettingsPresenter:
    ControllerLifeCycleObserver,
    SettingsViewOutput,
    SettingsInteractorOutput,
    MainQueuePerformable
{
    private weak var view: SettingsViewInput?
    var interactor: SettingsInteractorInput! // DI
    var router: SettingsRouterInput! // DI
    
    init(view: SettingsViewInput) { self.view = view }
    
    // MARK: - SettingsViewOutput
    func viewDidLoad() {
        view?.profileHeaderView.setState(.initial(type: .user))
        if let user = interactor.me {
            view?.profileHeaderView.setModel(user.profileInfoViewModel)
        } else {
            view?.showHUD(with: "Data is being loaded")
        }
    }
    
    func viewWillAppear() {
        interactor.setupObservers(
            DataSourceObserver<User>(
                contentWillChange: nil,
                contentDidChange: nil,
                didReceiveChange: { [weak self] change in
                    guard let self = self else { return }
                    self.onMainQueue {
                        if case .insert (let user, _) = change {
                            if (!user.me) { return }
                            self.view?.profileHeaderView.setModel(user.profileInfoViewModel)
                            self.view?.hideHUD()
                        }
                        if case .update (let user, _) = change {
                            if (!user.me) { return }
                            self.view?.profileHeaderView.setModel(user.profileInfoViewModel)
                            self.view?.hideHUD()
                        }
                    }
                }
            )
        )
    }
    
    func viewWillDisappear() {
        interactor.removeObservers()
    }
    
    func logout() {
        interactor.logout()
    }
    
    func logoutCompleted() {
        onMainQueue {
            self.router.showLoginStory()
        }
    }
    
    func editButtonPressed() {
        view?.allowEditing(true)
    }
    
    func saveButtonPressed() {
        view?.allowEditing(false)
        if userHasChanged() {
            view?.showHUD(with: "Saving...")
            interactor.editUser(
                with: view?.profileHeaderView.pictureName,
                and: view?.profileHeaderView.descriptionText
            )
        }
    }
    
    // MARK: - SettingsInteractorOutput -
    func userEditSuccess() {
        onMainQueue {
            self.view?.hideHUD()
            if let me = self.interactor.me {
                self.view?.profileHeaderView.setModel(me.profileInfoViewModel)
            } else {
                self.view?.showError("Internal error occured while editing.")
            }
        }
    }
    
    func failedToEditUser(with error: Error) {
        onMainQueue {
            self.view?.hideHUD()
            self.view?.showError(error)
        }
    }
    
    // MARK: - Private Methods -
    private func userHasChanged() -> Bool {
        guard let me = interactor.me else { return false }
        if view?.profileHeaderView.pictureName == nil
            && view?.profileHeaderView.descriptionText == nil { return false }
        if view?.profileHeaderView.pictureName == me.pictureName
            && view?.profileHeaderView.descriptionText == me.status { return false }
        return true
    }
}

fileprivate extension User {
    var profileInfoViewModel: ProfileInfoView.ProfileInfoViewModel {
        ProfileInfoView.ProfileInfoViewModel(
            title: displayName,
            pictureName: pictureName,
            description: status
        )
    }
}
