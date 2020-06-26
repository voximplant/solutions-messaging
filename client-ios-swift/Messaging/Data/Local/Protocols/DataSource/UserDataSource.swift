/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol UserDataSource: AnyObject {
    var me: User? { get }
    
    var allUsers: [User] { get }
    func getUser(at indexPath: IndexPath, includingMe: Bool) -> User
    func getUser(with id: NSNumber) -> User?
    func getNumberOfUsers(includingMe: Bool) -> Int
    func getPossibleToAddUsers(for conversation: Conversation) -> [User]
    
    func observeUsers(includingMe: Bool, observer: DataSourceObserver<User>)
    func removeObserver(_ observer: DataSourceObserver<User>)
}
