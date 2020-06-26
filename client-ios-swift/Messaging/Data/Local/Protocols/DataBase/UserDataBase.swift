/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

typealias UserDataBase = UserDataBaseInput & UserDataBaseOutput

protocol UserDataBaseInput {
    var me: User? { get }
    func saveUser(_ viUser: VIUser, me: Bool, completion: @escaping (Error?) -> Void)
    func updateUser(_ viUser: VIUser, completion: @escaping (Error?) -> Void)
}

extension UserDataBaseInput {
    func saveUser(_ user: (viUser: VIUser, me: Bool), completion: @escaping (Error?) -> Void) {
        saveUser(user.viUser, me: user.me, completion: completion)
    }
}

protocol UserDataBaseOutput {
    var userDataSource: UserDataSource { get }
}
