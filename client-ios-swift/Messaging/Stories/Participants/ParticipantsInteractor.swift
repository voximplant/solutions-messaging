/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ParticipantsInteractorInput: AnyObject {
    var activeConversation: Conversation { get }
    var numberOfParticipants: Int { get }
    var numberOfAdmins: Int { get }
    
    func getParticipant(at index: Int) -> Participant
    func getAdmin(at index: Int) -> Participant
    
    func remove(participant: User.ID)
    func remove(admin: User.ID)
    
    func setupObservers()
    func removeObservers()
}

protocol ParticipantsInteractorOutput: AnyObject {
    func conversationChanged(participantsChanged: Bool)
    func conversationDisappeared()
    func failedToRemove(with error: Error)
}

final class ParticipantsInteractor: ParticipantsInteractorInput {
    private weak var output: ParticipantsInteractorOutput?
    private let repository: Repository
    private let conversationDataSource: ConversationDataSource
    private var conversationObserver: DataSourceObserver<Conversation>?
    
    private(set) var activeConversation: Conversation
    var numberOfParticipants: Int { activeConversation.participants.filter{ !$0.user.me }.count }
    var numberOfAdmins: Int {
        activeConversation.participants.filter { $0.isOwner && !$0.user.me }.count
    }
    
    init(output: ParticipantsInteractorOutput,
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
    
    // MARK: - ParticipantsInteractorInput -
    func getParticipant(at index: Int) -> Participant {
        activeConversation.participants.filter { !$0.user.me }[index]
    }
    
    func getAdmin(at index: Int) -> Participant {
        activeConversation.participants.filter { $0.isOwner && !$0.user.me }[index]
    }
    
    func remove(participant: User.ID) {
        repository.removeUser(from: activeConversation, participant) { [weak self] error in
            if let error = error {
                self?.output?.failedToRemove(with: error)
            }
        }
    }
    
    func remove(admin: User.ID) {
        if var participant = activeConversation.participants.first(where: { $0.user.imID == admin }) {
            participant.isOwner = false
            participant.permissions = activeConversation.permissions
            repository.editParticipants([participant], in: activeConversation) { [weak self] error in
                if let error = error {
                    self?.output?.failedToRemove(with: error)
                }
            }
        } else {
            output?.failedToRemove(with: MessagingAppError.participantIsNotFound(participant: admin))
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

enum MessagingAppError: Error {
    case participantIsNotFound (participant: User.ID)
}
