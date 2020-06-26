/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol EventDataSource: AnyObject {
    func getNumberOfEvents(conversation: Conversation) -> Int
    func getEvent(conversation: Conversation, at indexPath: IndexPath) -> MessengerEvent
    func getLatestStoredEventSequence(conversationUUID uuid: String) -> Int64?
    func cleanCache()
    
    func observeConversation(uuid: String, observer: DataSourceObserver<MessengerEvent>)
    func removeObservers()
}
