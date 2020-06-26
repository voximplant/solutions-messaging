/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

enum VoxDemoError: Error {
    case userPasswordRequired
    case noDataReceived
    case dataParsingFailed
    case notLoggedIn
    case emptyConversationList
    case accessDenied
    case wrongUUID
    case noChanges
    case internalError
}

extension VoxDemoError {
    var localizedDescription: String {
        switch self {
        case .userPasswordRequired:
            return "User password is needed for login."
        case .noDataReceived:
            return "Did'nt receive any data from request."
        case .dataParsingFailed:
            return "Data parsing could'nt be completed."
        case .notLoggedIn:
            return "You're not logged in."
        case .emptyConversationList:
            return "Your conversation list is empty."
        case .accessDenied:
            return "You're trying to access data not for the current user"
        case .wrongUUID:
            return "Can't recreate because of not valid UUID"
        case .noChanges:
            return "No changes were made!"
        case .internalError:
            return "An internal error occured"
        }
    }
}
