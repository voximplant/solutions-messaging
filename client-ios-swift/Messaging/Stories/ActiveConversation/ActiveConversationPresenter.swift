/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

fileprivate typealias MessageCellConfigurator = TableCellConfigurator<MessageTableCell, MessageTableCellModel>
fileprivate typealias EventCellConfigurator = TableCellConfigurator<EventTableCell, EventTableCellModel>

final class ActiveConversationPresenter:
    Presenter,
    ActiveConversationViewOutput,
    ActiveConversationInteractorOutput
{
    private weak var view: ActiveConversationViewInput?
    var interactor: ActiveConversationInteractorInput!
    var router: ActiveConversationRouterInput!
    
    private var dataSource: TableDataSource!
    private var cellConfigurators: [CellConfigurator] {
        get { dataSource?.items.first ?? [] }
        set { dataSource?.items = [newValue] }
    }
    
    private var storedEvents: [MessengerEvent] = [] {
        didSet {
            cellConfigurators = storedEvents
                .compactMap { event -> MessengerCellModel? in
                    guard let myImId = interactor.me?.imID else { return nil }
                    if case .message (let messageEvent) = event {
                        let messageDialogViewOutput = MessageDialogViewOutput(
                            editAction: editButtonPressed(on:with:),
                            removeAction: removeButtonPressed(on:with:),
                            cancelAction: cancelButtonPressed(on:with:)
                        )
                        return MessageTableCellModel(with: messageEvent, myImId: myImId, and: messageDialogViewOutput)
                    }
                    if case .conversation (let conversationEvent) = event {
                        return EventTableCellModel(with: conversationEvent)
                    }
                    else { return nil }
            }
            .sorted { $0.sequence > $1.sequence }
            .compactMap { cellModel -> CellConfigurator? in
                switch cellModel {
                case is MessageTableCellModel:
                    return MessageCellConfigurator(model: cellModel as! MessageTableCellModel)
                case is EventTableCellModel:
                    return EventCellConfigurator(model: cellModel as! EventTableCellModel)
                default:
                    return nil
                }
            }
        }
    }
    
    private var conversation: Conversation {
        didSet {
            guard let view = view else { return }
            
            view.updateTitle(with: buildTitle(for: conversation))
            view.updateRightBarButtonImage(with: buildPictureName(for: conversation), and: buildTitle(for: conversation))
        }
    }
    
    private var type: ConversationType {
        return conversation.type
    }
    
    private var meIsAdmin: Bool? {
        return conversation.participants.first(where: { $0.user.imID == interactor.me?.imID })?.isOwner
    }
    
    private var isShowingTyping: Bool = false
    private var typingUsersArray: [String] = []
    
    private var conversationUpdated: Bool = false
    
    private var isInEditMessageMode: Bool = false
    private var currentlyEditedSequence: Int?
    
    required init(view: ActiveConversationViewInput, conversation: Conversation) {
        self.view = view
        self.conversation = conversation
    }
    
    // MARK: - ActiveConversationViewOutput -
    // MARK: - LifeCycle
    override func viewDidLoad() {
        guard let view = view else { return }
        
        dataSource = TableDataSource(items: [])
        
        view.updateTitle(with: buildTitle(for: conversation))
        view.updateRightBarButtonImage(with: buildPictureName(for: conversation), and: buildTitle(for: conversation))
        
        view.showActivityIndicator(true)
        interactor.requestConversation(for: conversation)
        view.showHUD(with: "Updating...")
        interactor.requestMessengerEvents(for: conversation)
        
        view.configureTableView(with: dataSource)
        view.configureTextView()
    }
    
    override func viewWillAppear() {
        interactor.viewWillAppear()
    }
    
    override func viewDidAppear() {
        guard let view = view else { return }
        
        if conversationUpdated {
            if updatingConversationCompletion == nil {
                view.showHUD(with: "Updating...")
                interactor.requestMessengerEvents(for: conversation)
            }
        }
    }
    
    func didAppearAfterEditing(with conversation: Conversation) {
        self.conversation = conversation
    }
    
    private var updatingConversationCompletion: (() -> Void)?
    
    // MARK: - Actions
    func rightBarButtonPressed() {
        router.showConversationInfoScreen(with: conversation)
    }
    
    func messageTextViewDidBeginEditing() {
        interactor.sendTyping(in: conversation)
    }
    
    func cancelEditPressed() {
        currentlyEditedSequence = nil
        isInEditMessageMode = false
        view?.hideEditMessageView()
        view?.clearMessageTextView()
    }
    
    // MARK: - Cell Actions
    func didLongTapCell(at indexPath: IndexPath) {
        guard let view = view else { return }
        
        view.deselectAllCells()
        
        if let configurator = cellConfigurators[indexPath.row] as? MessageCellConfigurator {
            if ((meIsAdmin == true && type != .direct) || configurator.model.isMy) { // TODO Improve permissions usage
                view.selectCell(at: indexPath)
            }
        }
    }
    
    func cancelButtonPressed(on cell: MessageTableCell, with sequence: Int) {
        cell.setSelected(false, animated: true)
    }
    
    func removeButtonPressed(on cell: MessageTableCell, with sequence: Int) {
        guard let event = storedEvents
            .first(where: { $0.sequence == sequence }) else { return }
        
        event.either(isMessageEvent: { messageEvent in
            self.view?.showHUD(with: "Removing...")
            self.interactor.remove(message: messageEvent.message)
        })
    }
    
    func editButtonPressed(on cell: MessageTableCell, with sequence: Int) {
        guard let view = view else { return }
        
        guard let index = (storedEvents.firstIndex {
            if case .message (let model) = $0 {
                if model.message.sequence == sequence {
                    return true
                }
            }
            return false
        }) else { return }
        
        cell.setSelected(false, animated: true)
        isInEditMessageMode = true
        
        storedEvents[index].either(isMessageEvent: {
            self.currentlyEditedSequence = $0.message.sequence
            view.showEditMessageView(with: $0.message.text)
            view.fillMessageTextView(with: $0.message.text)
        })
    }
    
    func sendTouchUp(with text: String) {
        guard let view = view else { return }
        
        view.showSending(true)
        
        if isInEditMessageMode {
            storedEvents.forEach { event in
                event.either(isMessageEvent: { messageEvent in
                    if messageEvent.message.sequence == self.currentlyEditedSequence {
                        if messageEvent.message.text == text {
                            view.showSending(false)
                            view.hideEditMessageView()
                        } else {
                            self.interactor.edit(message: messageEvent.message, with: text)
                        }
                    }
                })
            }
        } else {
            interactor.sendMessage(with: text, in: conversation)
        }
    }
    
    // MARK: - ActiveConversationInteractorOutput -
    // MARK: - Message
    func messageSent(_ messageEvent: MessageEvent) {
        guard let view = view else { return }
        
        storedEvents.append(MessengerEvent.message(messageEvent))
        view.insertCell(at: IndexPath(row: 0, section: 0))
        conversation.lastSequence += 1
        view.showSending(false)
        view.scrollToBottom()
        
        updatingConversationCompletion?()
    }
    
    func failedToSendMessage(with error: Error) {
        view?.showError(with: error.localizedDescription)
        view?.showSending(false)
        conversation.lastSequence -= 1
    } // TODO: should toggle msg isFailed
    
    func messageEventReceived(event: MessageEvent) {
        guard let view = view else { return }
        
        storedEvents.append(MessengerEvent.message(event))
        view.insertCell(at: IndexPath(row: 0, section: 0))
        conversation.lastSequence += 1
        view.scrollToBottom()
        sendRead()
    }
    
    func editMessageEventReceived(with event: MessageEvent) {
        guard let view = view else { return }
        
        guard let index = (storedEvents.firstIndex {
            if case .message (let model) = $0 {
                if model.message.uuid == event.message.uuid {
                    return true
                }
            }
            return false
        }) else { return }
        
        storedEvents[index].either(isMessageEvent: { messageEvent in
            let copy = messageEvent
            copy.action = .edit
            copy.message = Message(uuid: event.message.uuid, text: event.message.text,
                                   conversation: event.message.conversation, sequence: copy.message.sequence)
            self.storedEvents.remove(at: index)
            self.storedEvents.insert(MessengerEvent.message(copy), at: index)
        })
        
        view.showEditedCell(at: IndexPath(row: storedEvents.count - index - 1, section: 0), with: event.message.text)
    }
    
    func removeMessageEventReceived(with event: MessageEvent) {
        guard let view = view else { return }
        
        guard let index = (storedEvents.firstIndex {
            if case .message (let model) = $0 {
                if model.message.uuid == event.message.uuid {
                    return true
                }
            }
            return false
        }) else { return }
        
        storedEvents.remove(at: index)
        view.removeCell(at: IndexPath(row: storedEvents.count - index, section: 0)) // because table view is reverted
        
        conversation.lastSequence += 1
    }
    
    func didEdit(message: Message) {
        guard let view = view else { return }

        guard let index = (storedEvents.firstIndex {
            if case .message (let model) = $0 {
                if model.message.uuid == message.uuid {
                    return true
                }
            }
            return false
        }) else { return }
        
        storedEvents[index].either(isMessageEvent: { messageEvent in
            let copy = messageEvent
            copy.action = .edit
            copy.message = Message(uuid: message.uuid, text: message.text,
                                           conversation: message.conversation, sequence: copy.message.sequence)
            self.storedEvents.remove(at: index)
            self.storedEvents.insert(MessengerEvent.message(copy), at: index)
        })
        
        conversation.lastSequence += 1
        
        view.showEditedCell(at: IndexPath(row: storedEvents.count - index - 1, section: 0), with: message.text)
        
        currentlyEditedSequence = nil
        isInEditMessageMode = false
        view.showSending(false)
        view.hideEditMessageView()
        view.clearMessageTextView()
    }
    
    func failedToEditMessage(with error: Error) {
        guard let view = view else { return }
        
        view.showError(with: error.localizedDescription)
        currentlyEditedSequence = nil
        isInEditMessageMode = false
        view.showSending(false)
        view.hideEditMessageView()
        view.clearMessageTextView()
    }
    
    func didRemove(message: Message) {
        guard let view = view else { return }
        
        guard let index = storedEvents.firstIndex(where: {
            if case .message (let messageEvent) = $0 {
                if messageEvent.message.uuid == message.uuid {
                    return true
                }
            }
            return false
        }) else { return }
        
        storedEvents.remove(at: index)
        
        view.removeCell(at: IndexPath(row: storedEvents.count - index, section: 0))
        view.hideHUD()
        
        conversation.lastSequence += 1
    }
    
    func failedToRemoveMessage(with error: Error) {
        view?.hideHUD()
        view?.showError(with: error.localizedDescription)
    }
    
    // MARK: - Events
    func didReceive(events: [MessengerEvent]) {
        guard let view = view else { return }
        
        storedEvents = events
        view.updateTableView()
        view.hideHUD()
        checkRead()
        sendRead()
    }
    
    func failedToRequestEvents(with error: Error) {
        view?.showError(with: error.localizedDescription)
    }
    
    // MARK: - Typing
    func typingEventReceived(_ event: ServiceEvent) {
        guard let view = view else { return }
        
        typingUsersArray.append(event.initiator.displayName)
        updateArray()
        if !isShowingTyping { view.showIsTyping(true) }
        isShowingTyping = true
        
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(timerTick), userInfo: nil, repeats: false)
    }
    
    @objc func timerTick() {
        typingUsersArray.removeFirst()
        updateArray()
    }
    
    private func updateArray() {
        guard let view = view else { return }
        
        switch typingUsersArray.count {
        case 0:
            view.showIsTyping(false)
            isShowingTyping = false
        case 1:
            view.updateTypingLabel(with: "\(typingUsersArray[0]) is typing...")
        case 3...:
            view.updateTypingLabel(with: "\(typingUsersArray[0]) and \(typingUsersArray.count - 1) others are typing ")
        default:
            let stringFromArray = Array(Set(typingUsersArray)).joined(separator:", ")
            view.updateTypingLabel(with: "\(stringFromArray) are typing...")
        }
    }
    
    // MARK: - Read
    func readEventReceived(_ event: ServiceEvent) {
        guard let view = view else { return }
        
        conversation.latestReadSequence = event.sequence
        
        for (index, configurator) in cellConfigurators.enumerated() {
            if let configurator = configurator as? MessageCellConfigurator {
                if configurator.model.sequence <= event.sequence {
                    configurator.model.isRead = true
                    view.setReadOnCell(at: IndexPath(row: index, section: 0))
                }
            }
        }
    }
    
    // MARK: - Conversation
    func isConversationUUIDEqual(to UUID: String) -> Bool {
        return conversation.uuid == UUID
    }
    
    func didUpdate(conversation: Conversation) {
        guard let view = view else { return }
        
        view.showActivityIndicator(true)
        if !conversation.participants
            .contains(where: { $0.user.imID == interactor.me?.imID }) {
            view.showError(with: "You have been removed from the conversation")
            router.showConversationsScreen(with: conversation)
        } else {
            self.conversation = conversation
            setupType()
            conversationUpdated = true
            view.showActivityIndicator(false)
        }
    }
    
    func didRemove(conversation: Conversation) {
        guard let view = view else { return }
        
        view.showError(with: "Conversation was removed")
        router.showConversationsScreen(with: conversation)
    }
    
    func failedToRequestConversation(with error: Error) {
        view?.showError(with: error.localizedDescription)
    }
    
    // MARK: - User
    func didEdit(user: User) {
        guard view != nil else { return }
        
        if var participant = conversation.participants.first(where: { $0.user.imID == user.imID }) {
            participant.user = user
        }
    }
    
    // MARK: - Connection
    override func connectionLost() {
        view?.showHUD(with: "Connecting...")
        view?.showActivityIndicator(true)
    }
    
    override func tryingToLogin() {
        view?.showHUD(with: "Connecting...")
        view?.showActivityIndicator(true)
    }
    
    override func loginCompleted() {
        guard let view = view else { return }
        
        view.showActivityIndicator(true)
        interactor.requestConversation(for: conversation)
        
        view.showHUD(with: "Updating...")
        interactor.requestMessengerEvents(for: conversation)
        view.updateTitle(with: buildTitle(for: conversation))
    }
    
    override func loginFailed(with error: Error) {
        view?.showError(with: "Login failed")
    }
    
    // MARK: - Private Methods -
    private func setupType() {
        guard let view = view else { return }
        
        switch type {
        case .direct:
            view.showNewMessageContainer(true)
        case .chat:
            view.showNewMessageContainer(true)
            guard let me = conversation.participants.first(where: { $0.user.imID == interactor.me?.imID })
                else { fatalError() }
            view.showNewMessageContainer(me.permissions.canWrite)
        case .channel:
            guard let me = conversation.participants.first(where: { $0.user.imID == interactor.me?.imID })
                else { fatalError() }
            view.showNewMessageContainer(me.isOwner)
        }
    }
    
    private func buildTitle(for conversation: Conversation) -> String {
        if conversation.type == .direct
        {
            var displayName: String = ""
            conversation.participants.forEach
                { participant in
                    if participant.user.imID != interactor.me!.imID // ! is because at this moment we already logged in and me should be available
                    { displayName = participant.user.displayName }
                }
            return displayName
        }
        else { return conversation.title }
    }
    
    private func buildPictureName(for conversation: Conversation) -> String? {
        if conversation.type == .direct
        {
            var pictureName: String?
            conversation.participants.forEach
                { participant in
                    if participant.user.imID != interactor.me!.imID // ! is because at this moment we already logged in and me should be available
                    { pictureName = participant.user.pictureName }
                }
            return pictureName
        }
        else { return conversation.pictureName }
    }
    
    // MARK: - Read
    private func sendRead() {
        guard view != nil else { return }
        
        cellConfigurators.forEach { configurator in
            if let configurator = configurator as? MessageCellConfigurator {
                if !configurator.model.isMy && !configurator.model.isRead {
                    if configurator.model.sequence < self.conversation.latestReadSequence { return }
                    self.interactor.markAsRead(sequence: configurator.model.sequence, in: self.conversation)
                    self.conversation.latestReadSequence = configurator.model.sequence
                }
            }
        }
    }
    
    private func checkRead() {
        guard let view = view else { return }
        
        for (index, configurator) in cellConfigurators.enumerated() {
            if let configurator = configurator as? MessageCellConfigurator {
                if configurator.model.sequence <= self.conversation.latestReadSequence {
                    configurator.model.isRead = true
                    view.setReadOnCell(at: IndexPath(row: index, section: 0))
                }
            }
        }
    }
    
}
