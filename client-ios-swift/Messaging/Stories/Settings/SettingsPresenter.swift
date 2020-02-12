/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

final class SettingsPresenter: Presenter, SettingsViewOutput, SettingsInteractorOutput {
    weak var view: SettingsViewInput?
    
    var interactor: SettingsInteractorInput!
    var router: SettingsRouterInput!
    
    required init(view: SettingsViewInput) { self.view = view }
    
    func logoutPressed() {
        interactor.logout()
    }
    
    // MARK: - SettingsViewOutput
    override func viewDidLoad() {
        view?.setupHeaderViewAppearance(with: buildProfileModel(with: interactor.me))
    }
    
    override func viewWillAppear() {
        interactor.setupDelegates()
    }
    
    func logoutCompleted() {
        router.showLoginStory()
    }
    
    func editButtonPressed() {
        view?.allowEditing(true)
    }
    
    func saveButtonPressed() {
        view?.allowEditing(false)
        if userHasChanged() {
            view?.showHUD(with: "Saving...")
            interactor.editUser(with: view?.profileHeaderView.pictureName, and: view?.profileHeaderView.descriptionText)
        }
    }
    
    // MARK: - SettingsInteractorOutput -
    override func connectionLost() { view?.showError(with: "Connection lost") }
    
    override func tryingToLogin() {
        view?.showHUD(with: "Connecting...")
    }
    
    override func loginCompleted() {
        view?.hideHUD()
    }
    
    func userEditSuccess() {
        view?.hideHUD()
        view?.setupHeaderViewAppearance(with: buildProfileModel(with: interactor.me))
    }
    
    func failedToEditUser(with error: Error) {
        view?.hideHUD()
        view?.showError(with: error.localizedDescription)
    }
    
    // MARK: - Private Methods -
    
    private func userHasChanged() -> Bool {
        if view?.profileHeaderView.pictureName == nil
            && view?.profileHeaderView.descriptionText == nil { return false }
        if view?.profileHeaderView.pictureName == interactor.me.pictureName
            && view?.profileHeaderView.descriptionText == interactor.me.status { return false }
        return true
    }
    
    private func buildProfileModel(with user: User) -> UserProfileModel {
        return UserProfileModel(name: user.displayName, pictureName: user.pictureName, status: user.status)
    }
}
