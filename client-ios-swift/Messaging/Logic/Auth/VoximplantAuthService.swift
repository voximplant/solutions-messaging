/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

final class VoximplantAuthService: NSObject, VIClientSessionDelegate, AuthService {
    private let client: VIClient
    private var state: VIClientState { client.clientState }
    
    private var connectCompletion: ConnectCompletion?
    private var disconnectCompletion: DisconnectCompletion?
    
    @UserDefault("lastFullUsername")
    var loggedInUser: String?
    var possibleToLogin: Bool { Tokens.areExist && !Tokens.areExpired }
    let sdkVersion = (vox: VIClient.clientVersion(), webrtc: VIClient.webrtcVersion())
    
    var reconnectHandler: ((Error?) -> Void)?
    private var reconnectOperation: ReconnectOperation?
    private let serviceQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "reconnectQueue"
        queue.qualityOfService = .utility
        return queue
    }()
    
    private var willEnterForegroundObserver: NSObjectProtocol?
    
    init(client: VIClient) {
        self.client = client
        super.init()
        client.sessionDelegate = self
        willEnterForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: OperationQueue.main,
            using: { [weak self] _ in
                if let possibleToLogin = self?.possibleToLogin, possibleToLogin {
                    self?.reconnect()
                }
            }
        )
    }
    
    deinit {
        if let willEnterForegroundObserver = willEnterForegroundObserver {
            NotificationCenter.default.removeObserver(willEnterForegroundObserver)
        }
    }
    
    // MARK: - Login -
    func login(user: String, password: String, _ completion: @escaping LoginCompletion) {
        connect() { [weak self] error in
            if let error = error {
                completion(error)
                return
            }
            
            self?.client.login(withUser: user, password: password,
                success: { (displayUserName: String, tokens: VIAuthParams) in
                    Tokens.update(with: tokens)
                    self?.loggedInUser = user
                    completion(nil)
                },
                failure: { (error: Error) in
                    completion(error)
                }
            )
        }
    }
    
    func loginWithAccessToken(_ completion: @escaping LoginCompletion) {
        guard let user = self.loggedInUser else {
            completion(AuthError.loginDataNotFound)
            return
        }
        
        if client.clientState == .loggedIn,
            !Tokens.areExpired
        {
            completion(nil)
            return
        }
    
        connect() { [weak self] error in
            if let error = error  {
                completion(error)
                return
            }
            
            self?.updateAccessTokenIfNeeded(for: user) {
                [weak self]
                (result: Result<Token, Error>) in
                
                switch result {
                case let .failure(error):
                    completion(error)
                    return
                    
                case let .success(accessKey):
                    self?.client.login(withUser: user, token: accessKey.token,
                        success: { (displayUserName: String, tokens: VIAuthParams) in
                            Tokens.update(with: tokens)
                            self?.loggedInUser = user
                            completion(nil)
                        },
                        failure: { (error: Error) in
                            completion(error)
                        }
                    )
                }
            }
        }
    }
    
    private func updateAccessTokenIfNeeded(
        for user: String,
        _ completion: @escaping (Result<Token, Error>)->Void
    ) {
        guard let accessToken = Tokens.access,
            let refreshToken = Tokens.refresh else {
                completion(.failure(AuthError.loginDataNotFound))
                return
        }
        
        if accessToken.isExpired {
            client.refreshToken(withUser: user, token: refreshToken.token)
            { (authParams: VIAuthParams?, error: Error?) in
                guard let tokens = authParams
                else {
                    completion(.failure(error ?? VoxDemoError.internalError))
                    return
                }
                let updatedTokens = Tokens.update(with: tokens)
                completion(.success(updatedTokens.access))
            }
        } else {
            completion(.success(accessToken))
        }
    }
    
    // MARK: - Logout -
    func logout(_ completion: @escaping () -> Void) {
        Tokens.clear()
        loggedInUser = nil
        cancelReconnect()
        disconnect(completion)
    }
    
    // MARK: - Connect -
    private func connect(_ completion: @escaping ConnectCompletion) {
        if client.clientState == .disconnected ||
           client.clientState == .connecting
        {
            connectCompletion = completion
            client.connect()
        } else {
            completion(nil)
        }
    }
    
    private func disconnect(_ completion: @escaping DisconnectCompletion) {
        if client.clientState == .disconnected {
            completion()
        } else {
            disconnectCompletion = completion
            client.disconnect()
        }
    }
    
    // MARK: - Reconnect
    private func reconnect() {
        Log.i("Did begin reconnecting ")
        
        if reconnectOperation != nil {
            Log.i("Already reconnecting, return")
            return
        }
        
        let reconnectOperation = ReconnectOperation(
            attemptsLimit: 6,
            waitForTheNextAttempt: 3,
            timeout: 60,
            completion: { [weak self] error in
                self?.reconnectHandler?(error)
                self?.reconnectOperation = nil
            },
            login: loginWithAccessToken(_:)
        )
        self.reconnectOperation = reconnectOperation
        serviceQueue.addOperation(reconnectOperation)
    }
    
    private func cancelReconnect() {
        self.reconnectOperation?.cancel()
        self.reconnectOperation = nil
    }
    
    // MARK: VIClientSessionDelegate -
    func clientSessionDidConnect(_ client: VIClient) {
        connectCompletion?(nil)
        connectCompletion = nil
    }
    
    func clientSessionDidDisconnect(_ client: VIClient) {
        disconnectCompletion?()
        disconnectCompletion = nil
        if possibleToLogin && UIApplication.shared.applicationState != .background {
            reconnect()
        }
    }
    
    func client(_ client: VIClient, sessionDidFailConnectWithError error: Error) {
        connectCompletion?(error)
        connectCompletion = nil
        if possibleToLogin && UIApplication.shared.applicationState != .background {
            reconnect()
        }
    }
}
