/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import VoxImplantSDK

protocol VoximplantEventDelegate: AnyObject {
    func didReceive(conversationEvent: VIConversationEvent)
    func didReceive(messageEvent: VIMessageEvent)
    func didReceive(serviceEvent: VIConversationServiceEvent)
    func didReceive(userEvent: VIUserEvent)
}
