/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ConversationInfoInteractorInput {
    var numberOfParticipants: Int { get }
    var activeConversation: Conversation { get }
    func getParticipant(at index: Int) -> Participant
    func editConversation(_ conversation: Conversation, with title: String,
                          _ description: String?, _ pictureName: String?, isPublic: Bool?)
    func leaveConversation(_ conversation: Conversation)
    func setupObservers()
    func removeObservers()
}

protocol ConversationInfoInteractorOutput: AnyObject {
    func conversationChanged(participantsChanged: Bool)
    func conversationDisappeared()
    func failedToEditConversation(with error: Error)
    func failedToLeaveConversation(with error: Error)
}

final class ConversationInfoInteractor: ConversationInfoInteractorInput {
    private weak var output: ConversationInfoInteractorOutput?
    private let repository: Repository
    private let conversationDataSource: ConversationDataSource
    
    private(set) var activeConversation: Conversation
    private var conversationObserver: DataSourceObserver<Conversation>?
    var numberOfParticipants: Int { activeConversation.participants.count }
    
    init(output: ConversationInfoInteractorOutput,
         repository: Repository,
         conversationDataSource: ConversationDataSource,
         conversation: Conversation
    ) {
        self.output = output
        self.repository = repository
        self.conversationDataSource = conversationDataSource
        self.activeConversation = conversation
    }
    
    deinit {
        removeObservers()
    }
    
    // MARK: - ConversationInfoInteractorInput -
    func getParticipant(at index: Int) -> Participant {
        activeConversation.participants[index]
    }
    
    func editConversation(_ conversation: Conversation, with title: String,
                          _ description: String?, _ pictureName: String?,
                          isPublic: Bool?
    ) {
        repository.updateConversation(
            conversation,
            title: title,
            description: description,
            pictureName: pictureName,
            isPublic: isPublic
        ) { [weak self] error in
            if let error = error {
                self?.output?.failedToEditConversation(with: error) }
        }
    }
    
    func leaveConversation(_ conversation: Conversation) {
        repository.leaveConversation(conversation) { [weak self] error in
            if let error = error {
                self?.output?.failedToLeaveConversation(with: error)
            }
        }
    }
    
    func setupObservers() {
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
                    let participantsChanged = conversation.participants != self.activeConversation.participants
                    self.activeConversation = conversation
                    self.output?.conversationChanged(participantsChanged: participantsChanged)
                default:
                    break
                }
            }
        )
        self.conversationObserver = conversationObserver
        self.conversationDataSource.observeConversation(
            with: activeConversation.uuid,
            conversationObserver
        )
    }
    
    func removeObservers() {
        if let observer = conversationObserver {
            self.conversationDataSource.removeObserver(observer)
            self.conversationObserver = nil
        }
    }
}
