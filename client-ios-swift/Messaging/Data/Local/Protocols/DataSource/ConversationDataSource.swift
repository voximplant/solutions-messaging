/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ConversationDataSource: AnyObject {
    func getConversation(at indexPath: IndexPath) -> Conversation
    func getConversation(with uuid: String) -> Conversation?
    var numberOfConversations: Int { get }
    
    func observeConversation(with uuid: String, _ observer: DataSourceObserver<Conversation>)
    func observeConversations(_ observer: DataSourceObserver<Conversation>)
    func removeObserver(_ observer: DataSourceObserver<Conversation>)
}
