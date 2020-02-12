/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ParticipantsConfiguratorProtocol: AnyObject {
    func configure(with viewController: ParticipantsViewController, and type: ParticipantsModuleType)
}

final class ParticipantsConfigurator: ParticipantsConfiguratorProtocol {
    func configure(with viewController: ParticipantsViewController, and type: ParticipantsModuleType) {
        let presenter = ParticipantsPresenter(view: viewController, type: type)
        let interactor = ParticipantsInteractor(output: presenter)
        let router = ParticipantsRouter(viewController: viewController)
        
        viewController.output = presenter
        presenter.interactor = interactor
        presenter.router = router
        router.output = presenter
    }
}
