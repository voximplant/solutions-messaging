/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ActiveConversationInteractorInput: AnyObject {
    var me: User? { get }
    func viewWillAppear()
    func sendMessage(with text: String, in conversation: Conversation)
    func remove(message: Message)
    func edit(message: Message, with text: String)
    func sendTyping(in conversation: Conversation)
    func markAsRead(sequence: Int, in conversation: Conversation)
    func requestMessengerEvents(for conversation: Conversation)
    func requestConversation(for model: Conversation)
}

protocol ActiveConversationInteractorOutput: AnyObject, ConnectionEvents {
    func didReceive(events: [MessengerEvent])
    func typingEventReceived(_ event: ServiceEvent)
    func readEventReceived(_ event: ServiceEvent)
    func editMessageEventReceived(with event: MessageEvent)
    func removeMessageEventReceived(with event: MessageEvent)
    func messageEventReceived(event: MessageEvent)
    func didUpdate(conversation: Conversation)
    func didRemove(conversation: Conversation)
    func didRemove(message: Message)
    func didEdit(message: Message)
    func didEdit(user: User)
    func messageSent(_ messageEvent: MessageEvent)
    func failedToSendMessage(with error: Error)
    func failedToRequestEvents(with error: Error)
    func failedToRequestConversation(with error: Error)
    func failedToRemoveMessage(with error: Error)
    func failedToEditMessage(with error: Error)
    func isConversationUUIDEqual(to UUID: String) -> Bool
}

class ActiveConversationInteractor: ActiveConversationInteractorInput, RepositoryDelegate, AuthServiceDelegate {
    weak var output: ActiveConversationInteractorOutput?
    
    private let authService: AuthServiceProtocol = sharedAuthService
    private let repository: Repository = sharedRepository
    
    var me: User? { return repository.me }
    
    required init(output: ActiveConversationInteractorOutput) { self.output = output }
    
    // MARK: - ActiveConversationInteractorInput -
    func viewWillAppear() {
        repository.set(delegate: self)
        authService.set(delegate: self)
    }
    
    func requestMessengerEvents(for conversation: Conversation) {
        repository.requestMessengerEvents(for: conversation) { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToRequestEvents(with: error) }
            else if case .success (let events) = result { self.output?.didReceive(events: events) }
        }
    }
    
    func sendMessage(with text: String, in conversation: Conversation) {
        repository.sendMessage(with: text, in: conversation) {
            [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToSendMessage(with: error) }
            else if case .success (let messageEvent) = result { self.output?.messageSent(messageEvent) }
        }
    }
    
    func requestConversation(for model: Conversation) {
        repository.requestConversation(with: model.uuid) { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToRequestConversation(with: error) }
            else if case .success (let conversation) = result { self.output?.didUpdate(conversation: conversation) }
        }
    }
    
    func markAsRead(sequence: Int, in conversation: Conversation) {
        repository.markAsRead(sequence: Int64(sequence), in: conversation)
    }
    
    func sendTyping(in conversation: Conversation) {
        repository.sendTyping(to: conversation)
    }
    
    func remove(message: Message) {
        repository.remove(message: message) { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToRemoveMessage(with: error) }
            else if case .success (let event) = result { self.output?.didRemove(message: event.message) }
        }
    }
    
    func edit(message: Message, with text: String) {
        repository.edit(message: message, with: text) { [weak self] result in
            guard let self = self else { return }
            if case .failure (let error) = result { self.output?.failedToEditMessage(with: error) }
            else if case .success (let event) = result { self.output?.didEdit(message: event.message) }
        }
    }
    
    // MARK: - MessagingRepositoryDelegate -
    func didReceiveMessageEvent(_ event: MessageEvent) {
        guard let output = output else { return }
        if !output.isConversationUUIDEqual(to: event.message.conversation) { return }
        switch event.action {
        case .send   : output.messageEventReceived(event: event)
        case .edit   : output.editMessageEventReceived(with: event)
        case .remove : output.removeMessageEventReceived(with: event)
        }
    }
    
    func didReceiveConversationEvent(_ event: ConversationEvent) {
        guard let output = output else { return }
        if !output.isConversationUUIDEqual(to: event.conversation.uuid) { return }
        switch event.action {
        case .editConversation   : output.didUpdate(conversation: event.conversation)
        case .addParticipants    : output.didUpdate(conversation: event.conversation)
        case .removeParticipants : output.didUpdate(conversation: event.conversation)
        case .joinConversation   : output.didUpdate(conversation: event.conversation)
        case .leaveConversation  : output.didUpdate(conversation: event.conversation)
        case .removeConversation : output.didRemove(conversation: event.conversation)
        case .editParticipants   : output.didUpdate(conversation: event.conversation)
        case .createConversation : break
        }
    }
    
    func didReceiveServiceEvent(_ event: ServiceEvent) {
        guard let output = output else { return }
        if !output.isConversationUUIDEqual(to: event.conversationUUID) { return }
        switch event.action {
        case .typing : output.typingEventReceived(event)
        case .read   : output.readEventReceived(event)
        }
    }
    
    func didReceiveUserEvent(_ event: UserEvent) {
        guard let output = output else { return }
        switch event.action {
        case .editUser : output.didEdit(user: event.initiator)
        }
    }
    
    // MARK: - AuthServiceDelegate -
    func didDisconnect() {
        output?.connectionLost()
    }
    
    func reconnecting() {
        output?.tryingToLogin()
    }
    
    func didLogin(with displayName: String) {
        output?.loginCompleted()
    }
    
    func didFailToLogin(with error: Error) {
        output?.loginFailed(with: error)
    }
}
