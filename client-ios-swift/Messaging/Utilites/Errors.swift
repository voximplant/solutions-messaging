/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import Foundation
import VoxImplantSDK

let errorDomain = Bundle.main.bundleIdentifier!

enum VoxDemoError: Int {
    case userPasswordRequired = 5019
    case noDataReceived = 6000
    case dataParsingFailed = 6001
    case notLoggedIn = 6002
    case emptyConversationList = 6003
    case accessDenied = 6004
    case wrongUUID = 6005
    case noChanges = 6006
    
    private var description: String {
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
        }
    }
    
    var localizedDescriptionInfo: [String: Any] {
        return [NSLocalizedDescriptionKey: self.description]
    }
}


extension VoxDemoError {
    static func errorRequiredPassword() -> NSError {
        return NSError(domain: errorDomain,
                       code: VoxDemoError.userPasswordRequired.rawValue,
                       userInfo: VoxDemoError.userPasswordRequired.localizedDescriptionInfo)
    }
    
    static func errorNoDataReceived() -> NSError {
        return NSError(domain: errorDomain,
                       code: VoxDemoError.noDataReceived.rawValue,
                       userInfo: VoxDemoError.noDataReceived.localizedDescriptionInfo)
    }
    
    static func errorDataParsingFailed() -> NSError {
        return NSError(domain: errorDomain,
                       code: VoxDemoError.dataParsingFailed.rawValue,
                       userInfo: VoxDemoError.dataParsingFailed.localizedDescriptionInfo)
    }
    
    static func errorNotLoggedIn() -> NSError {
        return NSError(domain: errorDomain,
                       code: VoxDemoError.notLoggedIn.rawValue,
                       userInfo: VoxDemoError.notLoggedIn.localizedDescriptionInfo)
    }
    
    static func errorEmptyConversationList() -> NSError {
        return NSError(domain: errorDomain,
                       code: VoxDemoError.emptyConversationList.rawValue,
                       userInfo: VoxDemoError.emptyConversationList.localizedDescriptionInfo)
    }
    
    static func errorAcessDenied() -> NSError {
        return NSError(domain: errorDomain,
                       code: VoxDemoError.accessDenied.rawValue,
                       userInfo: VoxDemoError.accessDenied.localizedDescriptionInfo)
    }
    
    static func errorWrongUUID() -> NSError {
        return NSError(domain: errorDomain,
                       code: VoxDemoError.wrongUUID.rawValue,
                       userInfo: VoxDemoError.wrongUUID.localizedDescriptionInfo)
    }
    
    static func errorNoChanges() -> NSError {
        return NSError(domain: errorDomain,
                       code: VoxDemoError.noChanges.rawValue,
                       userInfo: VoxDemoError.noChanges.localizedDescriptionInfo)
    }
}
