/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ActiveConversationInteractorInput: AnyObject {
    var activeConversation: Conversation { get }
    var numberOfEvents: Int { get }
    func getEvent(at indexPath: IndexPath) -> MessengerEvent
    func setupObservers(events observer: DataSourceObserver<MessengerEvent>)
    func removeObservers()
    func sendMessage(with text: String)
    func editMessage(with uuid: String, text: String)
    func removeMessage(with uuid: String)
    func sendTyping()
    func markAsRead()
}

protocol ActiveConversationInteractorOutput: AnyObject {
    func conversationDisappeared()
    func conversationChanged(_ conversation: Conversation)
    func failedToSendMessage(with error: Error)
    func failedToRemoveMessage(with error: Error)
    func failedToEditMessage(with error: Error)
    func didReceiveTyping(from participant: Participant)
}

final class ActiveConversationInteractor: ActiveConversationInteractorInput {
    private weak var output: ActiveConversationInteractorOutput?
    private let repository: Repository
    
    private let conversationDataSource: ConversationDataSource
    private let eventDataSource: EventDataSource
    private let userDataSource: UserDataSource
    
    private(set) var activeConversation: Conversation
    var numberOfEvents: Int {
        eventDataSource.getNumberOfEvents(conversation: activeConversation)
    }
    
    private var conversationObserver: DataSourceObserver<Conversation>?
    
    init(output: ActiveConversationInteractorOutput,
         repository: Repository,
         conversation: Conversation,
         eventDataSource: EventDataSource,
         userDataSource: UserDataSource,
         conversationDataSource: ConversationDataSource
    ) {
        self.output = output
        self.eventDataSource = eventDataSource
        self.userDataSource = userDataSource
        self.activeConversation = conversation
        self.repository = repository
        self.conversationDataSource = conversationDataSource
    }
    
    // MARK: - ActiveConversationInteractorInput -
    func setupObservers(events observer: DataSourceObserver<MessengerEvent>) {
        let conversationObserver = DataSourceObserver<Conversation>(
            contentWillChange: nil,
            contentDidChange: nil,
            didReceiveChange: { [weak self] change in
                guard let self = self else { return }
                switch change {
                case .delete(_):
                    self.removeObservers()
                    self.output?.conversationDisappeared()
                case .update(let conversation, _):
                    self.activeConversation = conversation
                    self.output?.conversationChanged(conversation)
                default:
                    break
                }
            }
        )
        self.conversationObserver = conversationObserver
        conversationDataSource.observeConversation(with: activeConversation.uuid, conversationObserver)
        eventDataSource.observeConversation(uuid: activeConversation.uuid, observer: observer)
        repository.typingObserver = { [weak self] participant in
            self?.output?.didReceiveTyping(from: participant)
        }
    }
    
    func removeObservers() {
        if let conversationObserver = conversationObserver {
            conversationDataSource.removeObserver(conversationObserver)
        }
        eventDataSource.removeObservers()
        repository.typingObserver = nil
        self.conversationObserver = nil
    }
    
    deinit {
        removeObservers()
    }
    
    func getEvent(at indexPath: IndexPath) -> MessengerEvent {
        eventDataSource.getEvent(conversation: activeConversation, at: indexPath)
    }
    
    func markAsRead() {
        if activeConversation.lastReadSequence < activeConversation.lastSequence {
            Log.i("About to mark as read sequence \(activeConversation.lastSequence)")
            repository.markAsRead(
                sequence: Int64(activeConversation.lastSequence),
                conversation: activeConversation
            )
        }
    }
    
    func sendTyping() {
        repository.sendTyping(to: activeConversation)
    }
    
    func sendMessage(with text: String) {
        repository.sendMessage(
            with: text,
            conversation: activeConversation
        ) { [weak self] error in
            if let error = error {
                Log.e("Message sending failed with error \(error.localizedDescription)")
                self?.output?.failedToSendMessage(with: error)
            }
        }
    }
    
    func removeMessage(with uuid: String) {
        repository.removeMessage(with: uuid, conversation: activeConversation.uuid) { [weak self] error in
            if let error = error {
                Log.e("Message removing failed with error \(error.localizedDescription)")
                self?.output?.failedToRemoveMessage(with: error)
            }
        }
    }
    
    func editMessage(with uuid: String, text: String) {
        repository.editMessage(with: uuid, conversation: activeConversation.uuid, text: text) { [weak self] error in
            if let error = error {
                Log.e("Message editing failed with error \(error.localizedDescription)")
                self?.output?.failedToEditMessage(with: error)
            }
        }
    }
}
