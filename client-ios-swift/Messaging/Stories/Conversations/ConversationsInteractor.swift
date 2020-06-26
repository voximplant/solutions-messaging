/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ConversationsInteractorInput: AnyObject {
    var numberOfConversations: Int { get }
    func setupObservers(_ observer: DataSourceObserver<Conversation>)
    func removeObservers()
    func getConversation(at indexPath: IndexPath) -> Conversation
}

protocol ConversationsInteractorOutput: AnyObject {
    func fetchingFailed(with error: Error)
}

final class ConversationsInteractor: ConversationsInteractorInput {
    private weak var output: ConversationsInteractorOutput?
    private let conversationDataSource: ConversationDataSource
    private var observer: DataSourceObserver<Conversation>?
    
    var numberOfConversations: Int { conversationDataSource.numberOfConversations }
    
    init(output: ConversationsInteractorOutput,
         conversationDataSource: ConversationDataSource
    ) {
        self.output = output
        self.conversationDataSource = conversationDataSource
    }
    
    deinit {
        removeObservers()
    }
    
    // MARK: - ConversationsInteractorInput -
    func getConversation(at indexPath: IndexPath) -> Conversation {
        conversationDataSource.getConversation(at: indexPath)
    }
    
    func setupObservers(_ observer: DataSourceObserver<Conversation>) {
        self.observer = observer
        conversationDataSource.observeConversations(observer)
    }
    
    func removeObservers() {
        if let observer = observer {
            conversationDataSource.removeObserver(observer)
            self.observer = nil
        }
    }
}
