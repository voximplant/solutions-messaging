/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol SettingsConfiguratorProtocol: AnyObject {
    func configure(with viewController: SettingsViewController)
}

final class SettingsConfigurator: SettingsConfiguratorProtocol {
    private let repositopy: Repository
    private let authService: AuthService
    private let userDataSource: UserDataSource
    private let dataBaseCleaner: Cleanable
    
    required init(
        repository: Repository,
        authService: AuthService,
        userDataSource: UserDataSource,
        dataBaseCleaner: Cleanable
    ) {
        self.repositopy = repository
        self.authService = authService
        self.userDataSource = userDataSource
        self.dataBaseCleaner = dataBaseCleaner
    }
    
    func configure(with viewController: SettingsViewController) {
        let presenter = SettingsPresenter(view: viewController)
        let interactor = SettingsInteractor(
            output: presenter,
            authService: authService,
            repository: repositopy,
            userDataSource: userDataSource,
            dataBaseCleaner: dataBaseCleaner
        )
        let router = SettingsRouter(viewController: viewController)
        viewController.output = presenter
        presenter.interactor = interactor
        presenter.router = router
    }    
}
