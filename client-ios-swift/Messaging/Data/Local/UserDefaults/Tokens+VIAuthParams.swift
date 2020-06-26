/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

extension Tokens {
    @discardableResult static func update(with authParams: VIAuthParams)
        -> (access: Token, refresh: Token) {
        let access = Token(
            token: authParams.accessToken,
            expireDate: Date(timeIntervalSinceNow: authParams.accessExpire)
        )
        self.access = access
        
        let refresh = Token(
            token: authParams.refreshToken,
            expireDate: Date(timeIntervalSinceNow: authParams.refreshExpire)
        )
        self.refresh = refresh
        
        return (access, refresh)
    }
}
