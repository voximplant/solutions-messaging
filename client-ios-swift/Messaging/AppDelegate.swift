/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit
import VoxImplantSDK

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        CoreDataController { coreDataController in
            let client = VIClient(
                delegateQueue: DispatchQueue.main,
                bundleId: Bundle.main.bundleIdentifier
            )
            let voximplantService: VoximplantDataSource = VoximplantService(with: client.messenger)
            let backend: Backend = BackendService()
            let authService = VoximplantAuthService(client: client)
            let repository = MessagingRepository(
                backend: backend,
                voximplantService: voximplantService,
                dataBase: coreDataController
            )
            authService.reconnectHandler = { error in
                if let error = error {
                    Log.e("Reconnect failed with error \(error.localizedDescription)")
                } else {
                    repository.refresh()
                }
            }
            StoryConfiguratorFactory.authService = authService
            StoryConfiguratorFactory.repository = repository
            StoryConfiguratorFactory.dataRefresher = repository
            StoryConfiguratorFactory.userDataSource = coreDataController.userDataSource
            StoryConfiguratorFactory.conversationDataSource = coreDataController.conversationDataSource
            StoryConfiguratorFactory.eventDataSource = coreDataController.eventDataSource
            StoryConfiguratorFactory.dataBaseCleaner = coreDataController
            
            if authService.possibleToLogin {
                authService.loginWithAccessToken { result in
                    repository.refresh()
                }
            }
            
            self.setupInitialController(canLogin: authService.possibleToLogin)
        }
        
        return true
    }
    
    private func setupInitialController(canLogin: Bool) {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = canLogin
            ? ConversationsRouter.moduleEntryController
            : LoginRouter.moduleEntryController
        window?.makeKeyAndVisible()
    }
}
