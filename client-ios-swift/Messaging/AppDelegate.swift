/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit
import VoxImplantSDK

fileprivate let client = VIClient(delegateQueue: DispatchQueue.main, bundleId: Bundle.main.bundleIdentifier)
fileprivate let voximplantService: MessagingDataSource = VoximplantService(with: client.messenger)
fileprivate let coreDataManager: MessagingDataSource = CoreDataManager()
let sharedAuthService: AuthServiceProtocol = AuthService(client: client)
let sharedRepository: Repository = MessagingRepository(remote: voximplantService, local: coreDataManager)

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private let authService = sharedAuthService
    
    private func setupInitialController() {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = authService.possibleToLogin()
            ? ConversationsRouter.moduleEntryController
            : LoginRouter.moduleEntryController
        window?.makeKeyAndVisible()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupInitialController()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) { }

    func applicationDidEnterBackground(_ application: UIApplication) { }

    func applicationWillEnterForeground(_ application: UIApplication) { }

    func applicationDidBecomeActive(_ application: UIApplication) { }

    func applicationWillTerminate(_ application: UIApplication) { }
}
