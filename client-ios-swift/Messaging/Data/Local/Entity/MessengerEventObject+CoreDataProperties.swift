/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import CoreData

extension MessengerEventObject {
    @NSManaged public var sequence: Int64
    @NSManaged public var timestamp: Double
    @NSManaged public var conversation: ConversationObject
    @NSManaged public var initiator: UserObject
}
