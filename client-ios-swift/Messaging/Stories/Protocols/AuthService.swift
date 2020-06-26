/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

typealias ConnectCompletion = (Error?) -> Void
typealias DisconnectCompletion = () -> Void
typealias LoginCompletion = (Error?) -> Void

protocol AuthService: AnyObject {
    var sdkVersion: (vox: String, webrtc: String) { get }
    var loggedInUser: String? { get }
    var reconnectHandler: ((Error?) -> Void)? { get set }
    var possibleToLogin: Bool { get }
    func login(user: String, password: String, _ completion: @escaping LoginCompletion)
    func loginWithAccessToken(_ completion: @escaping LoginCompletion)
    func logout(_ completion: @escaping () -> Void)
}
