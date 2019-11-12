/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol RepositoryDelegate: AnyObject {
    func didReceiveMessageEvent(_ event: MessageEvent)
    func didReceiveConversationEvent(_ event: ConversationEvent)
    func didReceiveServiceEvent(_ event: ServiceEvent)
    func didReceiveUserEvent(_ event: UserEvent)
}

extension RepositoryDelegate {
    func didReceiveMessageEvent(_ event: MessageEvent) { }
    func didReceiveConversationEvent(_ event: ConversationEvent) { }
    func didReceiveServiceEvent(_ event: ServiceEvent) { }
    func didReceiveUserEvent(_ event: UserEvent) { }
}
