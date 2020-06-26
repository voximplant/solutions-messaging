/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

enum ReconnectError: Error {
    case reconnectFailed
    case timeout
    
    var localizedDescription: String {
        switch self {
        case .reconnectFailed:
            return "Unable to reconnect"
        case .timeout:
            return "Reconnect timeout"
        }
    }
}
