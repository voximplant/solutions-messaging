/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

enum AuthError: Error {
    case loginDataNotFound
    
    var localizedDescription: String {
        switch self {
        case .loginDataNotFound:
            return "Login data was not found, try to login with password"
        }
    }
}
