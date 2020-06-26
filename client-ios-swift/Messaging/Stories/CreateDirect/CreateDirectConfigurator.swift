/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol CreateDirectConfiguratorProtocol: AnyObject {
    func configure(with viewController: CreateDirectViewController)
}

final class CreateDirectConfigurator: CreateDirectConfiguratorProtocol {
    private let repositopy: Repository
    private let userDataSource: UserDataSource
    
    required init(repository: Repository, userDataSource: UserDataSource) {
        self.repositopy = repository
        self.userDataSource = userDataSource
    }
    
    func configure(with viewController: CreateDirectViewController) {
        let presenter = CreateDirectPresenter(view: viewController)
        let userListPresenter = UserListPresenter(
            view: viewController.userListView,
            output: presenter
        )
        viewController.userListView.output = userListPresenter
        presenter.userListInput = userListPresenter
        viewController.output = presenter
        let interactor = CreateDirectInteractor(
            output: presenter,
            repository: repositopy,
            userDataSource: userDataSource
        )
        let router = CreateDirectRouter(viewController: viewController)
        presenter.interactor = interactor
        presenter.router = router
    }
}
