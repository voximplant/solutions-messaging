/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

protocol LoginConfiguratorProtocol: AnyObject {
    func configure(with viewController: LoginViewController)
}

final class LoginConfigurator: LoginConfiguratorProtocol {
    private let authService: AuthService
    private let dataRefresher: DataRefresher
    
    required init(authService: AuthService, dataRefresher: DataRefresher) {
        self.authService = authService
        self.dataRefresher = dataRefresher
    }
    
    func configure(with viewController: LoginViewController) {
        let presenter = LoginPresenter(view: viewController)
        let interactor = LoginInteractor(output: presenter, dataRefresher: dataRefresher, authService: authService)
        let router = LoginRouter(viewController: viewController)
        
        viewController.output = presenter
        presenter.interactor = interactor
        presenter.router = router
    }
}
