/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol AddParticipantsInteractorInput: AnyObject {
    var activeConversation: Conversation { get }
    var numberOfParticipants: Int { get }
    var numberOfAdmins: Int { get }
    
    func getParticipant(at index: Int) -> User
    func getAdmin(at index: Int) -> Participant
    
    func addUsers(_ users: Set<User.ID>)
    func addAdmins(_ users: Set<User.ID>)
    
    func setupObservers()
    func removeObservers()
}

protocol AddParticipantsInteractorOutput: AnyObject {
    func conversationChanged(participantsChanged: Bool)
    func conversationDisappeared()
    func failedToAddUsers(with error: Error)
    func failedToAddAdmins(with error: Error)
}

final class AddParticipantsInteractor: AddParticipantsInteractorInput {
    private weak var output: AddParticipantsInteractorOutput?
    private let repository: Repository
    private let userDataSource: UserDataSource
    private let conversationDataSource: ConversationDataSource
    private var conversationObserver: DataSourceObserver<Conversation>?
    
    private(set) var activeConversation: Conversation
    var numberOfParticipants: Int {
        userDataSource.allUsers.count - activeConversation.participants.count
    }
    var numberOfAdmins: Int {
        activeConversation.participants.filter { !$0.isOwner && !$0.user.me }.count
    }
    
    init(output: AddParticipantsInteractorOutput,
         repository: Repository,
         conversationDataSource: ConversationDataSource,
         userDataSource: UserDataSource,
         conversation: Conversation
    ) {
        self.output = output
        self.repository = repository
        self.conversationDataSource = conversationDataSource
        self.userDataSource = userDataSource
        self.activeConversation = conversation
    }
    
    deinit {
        removeObservers()
    }
    
    // MARK: - AddParticipantsInteractorInput
    func getParticipant(at index: Int) -> User {
        let allUsers = userDataSource.allUsers
        let participants = activeConversation.participants.map(\.user)
        let result = allUsers.filter { !participants.contains($0) }
        
        return result[index]
    }
    
    func getAdmin(at index: Int) -> Participant {
        activeConversation.participants.filter { !$0.isOwner && !$0.user.me }[index]
    }
    
    func addUsers(_ users: Set<User.ID>) {
        repository.addUsers(to: activeConversation, users: users) { [weak self] error in
            if let error = error {
                self?.output?.failedToAddUsers(with: error)
            }
        }
    }
    
    func addAdmins(_ users: Set<User.ID>) {
        let participants = users.compactMap { (id) -> Participant? in
            var participant = activeConversation.participants.first(where: { $0.user.imID == id })
            participant?.isOwner = true
            participant?.permissions = Permissions.defaultForAdmin()
            return participant
        }
        repository.editParticipants(participants, in: activeConversation) { [weak self] error in
            if let error = error {
                self?.output?.failedToAddAdmins(with: error)
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
