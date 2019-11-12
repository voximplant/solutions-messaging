/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation
import VoxImplant

protocol AuthServiceDelegate: AnyObject {
    func didLogin(with displayName: String)
    func didFailToLogin(with error: Error)
    func didDisconnect()
    func reconnecting()
}

protocol AuthServiceProtocol: AnyObject {
    func set(delegate: AuthServiceDelegate)
    
    var sdkVersion: (vox: String, webrtc: String) { get }
    var loggedInUser: String? { get }
    
    func possibleToLogin() -> Bool
    func login(user: String, password: String, _ completion: @escaping (Result<String, Error>) -> Void)
    func loginWithAccessToken(_ completion: @escaping (Result<String, Error>) -> Void)
    func logout(_ completion: @escaping () -> Void)
}

class AuthService: NSObject, VIClientSessionDelegate, AuthServiceProtocol {
    private weak var delegate: AuthServiceDelegate?
    
    private let client: VIClient
    private var state: VIClientState { return client.clientState }
    
    private var connectCompletion: ((Result<(), Error>)->Void)?
    private var disconnectCompletion: (() -> Void)?
    
    private var tokenManager = TokenManager()
    private(set) var loggedInUser: String? {
        get { return userDefaults.string(forKey: userDefaults.lastFullUsername) }
        set { userDefaults.set(newValue, forKey: userDefaults.lastFullUsername) }
    }
    private var loggedInUserDisplayName: String?
    
    let sdkVersion = (vox: VIClient.clientVersion(), webrtc: VIClient.webrtcVersion())
    
    func set(delegate: AuthServiceDelegate) {
        self.delegate = delegate
    }
    
    init(client: VIClient) {
        self.client = client
        super.init()
        client.sessionDelegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc func willEnterForeground() {
        if possibleToLogin() { reconnect() }
    }
    
    // MARK: - Login -
    func login(user: String, password: String, _ completion: @escaping (Result<String, Error>) -> Void) {
        log("Logging in")
        
        if let loggedInDisplayName = loggedInUserDisplayName, state == .loggedIn { completion(.success(loggedInDisplayName)) }
        
        connect() { result in
            if case let .failure(error) = result {
                completion(.failure(error))
                return
            }
            
            self.client.login(withUser: user, password: password, success:
                { (displayName, tokens) in
                    
                    if let refreshToken = tokens.refreshToken,
                       let accessToken = tokens.accessToken
                    {
                        self.tokenManager.keys = (accessToken, refreshToken)
                        self.loggedInUser = user
                        self.loggedInUserDisplayName = displayName
                    }
                    
                    completion(.success(displayName)) },
                              
                              failure: { error in completion(.failure(error)) })
        }
    }
    
    func loginWithAccessToken(_ completion: @escaping (Result<String, Error>) -> Void) {
        guard let user = self.loggedInUser else {
            let error = VoxDemoError.errorRequiredPassword()
            completion(.failure(error))
            return
        }
        
        if client.clientState == .loggedIn,
            let loggedInUserDisplayName = self.loggedInUserDisplayName, possibleToLogin() {
            completion(.success(loggedInUserDisplayName))
            return
        }
        
        connect() { result in
            if case let .failure(error) = result {
                completion(.failure(error))
                return
            }
            
            self.updateAccessTokenIfNeeded(for: user) { result in
                switch result {
                case let .failure(error):
                    completion(.failure(error))
                    return
                    
                case let .success(accessKey):

                    self.client.login(withUser: user, token: accessKey.token,
                                      
                                      success: { (displayName, tokens) in

                                        if let accessToken = tokens.accessToken,
                                            let refreshToken = tokens.refreshToken
                                        {
                                            self.tokenManager.keys = (accessToken, refreshToken)
                                            self.loggedInUser = user
                                            self.loggedInUserDisplayName = displayName
                                        }
                                        
                                        completion(.success(displayName)) },
                                      
                                      failure: {
                                        error in completion(.failure(error))
                    })
                }
            }
        }
    }
    
    func possibleToLogin() -> Bool {
        guard let keys = tokenManager.keys else { return false }
        return !keys.refresh.isExpired
    }
    
    private func updateAccessTokenIfNeeded(for user: String, _ completion: @escaping (Result<Token, Error>) -> Void) {
        guard let tokens = tokenManager.keys else {
            completion(.failure(VoxDemoError.errorRequiredPassword()))
            return
        }
        
        if tokens.access.isExpired {
            client.refreshToken(withUser: user, token: tokens.refresh.token) { [weak self] (authParams, error) in
                guard let tokens = authParams,
                    let refreshToken = tokens.refreshToken,
                    let accessToken = tokens.accessToken else {
                        completion(.failure(error!))
                        return
                }
                self?.tokenManager.keys = (accessToken, refreshToken)
                completion(.success(accessToken))
            }
        } else {
            completion(.success(tokens.access))
        }
    }
    
    // MARK: - Logout -
    func logout(_ completion: @escaping () -> Void) {
        tokenManager.removeKeys()
        disconnect(completion)
    }
    
    // MARK: - Connect -
    private func connect(_ completion: @escaping (Result<(), Error>) -> Void) {
        if client.clientState == .disconnected || client.clientState == .connecting {
            connectCompletion = completion
            client.connect()
        } else {
            completion(.success(()))
        }
    }
    
    private func disconnect(_ completion: @escaping () -> Void) {
        if client.clientState != .disconnected {
            disconnectCompletion = completion
            client.disconnect()
        } else {
            completion()
        }
    }
    
    // MARK: VIClientSessionDelegate -
    func clientSessionDidConnect(_ client: VIClient) {
        connectCompletion?(.success(()))
        connectCompletion = nil
    }
    
    func clientSessionDidDisconnect(_ client: VIClient) {
        delegate?.didDisconnect()
        disconnectCompletion?()
        disconnectCompletion = nil
        if possibleToLogin() && UIApplication.shared.applicationState != .background
        { reconnect() }
    }
    
    func client(_ client: VIClient, sessionDidFailConnectWithError error: Error) {
        connectCompletion?(.failure(error))
        connectCompletion = nil
        if possibleToLogin() && UIApplication.shared.applicationState != .background
        { reconnect() }
    }
    
    // MARK: - Private Methods -
    private func reconnect() {
        delegate?.reconnecting()
        loginWithAccessToken { result in
            if case .failure (let error) = result {
                if (error as NSError).code == 10001 { return } // ignoring request to balancer failed error
                else { self.delegate?.didFailToLogin(with: error) }
                self.reconnect()
            }
            else if case .success (let displayName) = result { self.delegate?.didLogin(with: displayName) }
        }
    }
}

// MARK: - Extensions -
fileprivate extension Dictionary where Key == AnyHashable {
    var refreshExpire: Date? {
        get {
            if let refreshExpire = self["refreshExpire"] as? Int
            { return Date(timeIntervalSinceNow: TimeInterval(refreshExpire)) }
            else { return nil }
        }
    }
    
    var refreshTokenContent: String? {
        get { return self["refreshToken"] as? String }
    }
    
    var accessExpire: Date? {
        get {
            if let accessExpire = self["accessExpire"] as? Int
            { return Date(timeIntervalSinceNow: TimeInterval(accessExpire)) }
            else { return nil }
        }
    }
    
    var accessTokenContent: String? {
        get { return self["accessToken"] as? String }
    }
    
    var accessToken: Token? {
        get {
            if let accessExpire = self.accessExpire,
               let accessTokenContent = self.accessTokenContent
            { return Token(token: accessTokenContent, expireDate: accessExpire) }
            else { return nil }
        }
    }
    
    var refreshToken: Token? {
        get {
            if let refreshExpire = self.refreshExpire,
               let refreshTokenContent = self.refreshTokenContent
            { return Token(token: refreshTokenContent, expireDate: refreshExpire) }
            else { return nil }
        }
    }
}

fileprivate let userDefaults = UserDefaults.standard
fileprivate extension UserDefaults {
    var lastFullUsername: String
    { return UIApplication.userDefaultsDomain + "." + "lastFullUsername" }
}
