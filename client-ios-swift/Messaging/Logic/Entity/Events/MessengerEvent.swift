/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

protocol MessengerEvent {
    var initiator: User { get }
    var conversation: Conversation { get }
    var sequence: Int { get }
}
