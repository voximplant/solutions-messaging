/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import CoreData
import VoxImplantSDK

extension UserObject {
    @NSManaged public var displayName: String
    @NSManaged public var imId: Int64
    @NSManaged public var me: Bool
    @NSManaged public var pictureName: String?
    @NSManaged public var status: String?
    @NSManaged public var username: String
}

extension UserObject: ManagedObject {
    var id: Int64 { imId }
    
    var converted: User {
        User(imID: imId,
             me: me,
             username: username,
             displayName: displayName,
             pictureName: pictureName,
             status: status)
    }
    
    static func makeFetchRequest(for key: Int64) -> NSFetchRequest<UserObject> {
        let fetchRequest: NSFetchRequest<UserObject> = defaultFetchRequest
        fetchRequest.predicate = NSPredicate(
            format: "imId == %@",
            argumentArray: [key]
        )
        return fetchRequest
    }
    
    func update(from value: VIUser) {
        imId = Int64(truncating: value.imId)
        displayName = value.displayName
        username = value.name
        pictureName = value.customData.image
        status = value.customData.status
    }
}

extension UserObject: Predicatable {
    // if predicate = true - return any user
    // else - return return true for everyone except me
    func satisfiesPredicate(_ predicate: Bool) -> Bool {
        predicate || me == predicate
    }
}
