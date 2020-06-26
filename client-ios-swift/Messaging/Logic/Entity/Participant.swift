/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

struct Participant: Equatable {
    var isOwner: Bool
    var user: User
    var permissions: Permissions
    var lastReadEventSequence: Int
}
