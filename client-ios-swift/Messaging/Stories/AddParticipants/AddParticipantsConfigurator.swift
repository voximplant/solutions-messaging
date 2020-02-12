/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol AddParticipantsConfiguratorProtocol: AnyObject {
    func configure(with viewController: AddParticipantsViewController, and type: AddParticipantsModuleType)
}

final class AddParticipantsConfigurator {
    func configure(with viewController: AddParticipantsViewController, and type: AddParticipantsModuleType) {
        let presenter = AddParticipantsPresenter(view: viewController, type: type)
        let interactor = AddParticipantsInteractor(output: presenter)
        let router = AddParticipantsRouter(viewController: viewController)
        
        viewController.output = presenter
        presenter.interactor = interactor
        presenter.router = router
        router.output = presenter
    }
}
