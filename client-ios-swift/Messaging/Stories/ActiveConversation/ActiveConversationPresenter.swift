/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit

final class ActiveConversationPresenter:
    ControllerLifeCycleObserver,
    ActiveConversationViewOutput,
    ActiveConversationInteractorOutput,
    MainQueuePerformable
{
    private typealias MessageCellConfigurator
        = TableCellConfigurator<MessageTableCell, MessageTableCellModel>
    private typealias EventCellConfigurator
        = TableCellConfigurator<EventTableCell, EventTableCellModel>
    
    private weak var view: ActiveConversationViewInput?
    var interactor: ActiveConversationInteractorInput! // DI
    var router: ActiveConversationRouterInput! // DI
    
    private var conversation: Conversation { interactor.activeConversation }
    private var me: Participant? {
        conversation.participants.first { $0.user.me }
    }
    private var type: Conversation.ConversationType { conversation.type }
    private var isShowingTyping: Bool { !typingUsersArray.isEmpty }
    private var typingUsersArray: [String] = []
    private var isInEditMessageMode: Bool { currentlyEditedMessage != nil }
    private var currentlyEditedMessage: MessageTableCellModel?
    private var appearedMoreThanOnce: Bool = false
    private var onTheScreen: Bool = false
    
    init(view: ActiveConversationViewInput) { self.view = view }
    
    // MARK: - ActiveConversationViewOutput -
    func viewDidLoad() {
        view?.title = conversation.title
        view?.updateRightBarButtonImage(with: conversation.pictureName, and: conversation.title)
        
        view?.configureTableView(
            with: ActiveConversationTableDataSource(
                numberOfItems: { [weak self] in
                    self?.interactor.numberOfEvents ?? 0
                },
                configurator: { [weak self] indexPath in
                    guard let self = self,
                        let me = self.me
                        else {
                            return EventCellConfigurator(model: EventTableCellModel(sequence: 0, text: ""))
                    }
                    let event = self.interactor.getEvent(at: indexPath)
                    if let conversationEvent = event as? ConversationEvent {
                        return EventCellConfigurator(model: EventTableCellModel(with: conversationEvent))
                    }
                    if let message = event as? MessageEvent {
                        return MessageCellConfigurator(
                            model: MessageTableCellModel(
                                with: message,
                                and: MessageTableCellModel.MessageTableCellOutput(
                                    editMessage: { [weak self] cell, model in
                                        cell.setSelected(false, animated: true)
                                        self?.currentlyEditedMessage = model
                                        self?.view?.showEditMessageView(with: model.text)
                                        self?.view?.fillMessageTextView(with: model.text)
                                    },
                                    removeMessage: { [weak self] _, model in
                                        self?.view?.showHUD(with: "Removing...")
                                        self?.interactor.removeMessage(with: model.uuid)
                                        // HUD will be hidden after result received via presenter input
                                    },
                                    closeOptions: { cell, _ in
                                        cell.setSelected(false, animated: true)
                                }
                                ),
                                permissions: (
                                    edit: message.initiator.me
                                        ? me.isOwner || me.permissions.canEditMessages
                                        : me.isOwner || me.permissions.canEditAllMessages
                                    , remove: message.initiator.me
                                        ? me.isOwner || me.permissions.canRemoveMessages
                                        : me.isOwner || me.permissions.canRemoveAllMessages
                                )
                            )
                        )
                    }
                    // should never happen
                    Log.e("Did receive an unknown event from the interactor \(String(describing: event))")
                    return EventCellConfigurator(model: EventTableCellModel(sequence: 0, text: ""))
                }
            )
        )
        
        refreshUI(includingMessages: false)
        
        interactor.setupObservers(
            events: DataSourceObserver<MessengerEvent>(
                contentWillChange: { [weak self] in
                    self?.onMainQueue {
                        if self?.onTheScreen ?? false {
                            self?.view?.beginUpdate()
                        }
                    }
                },
                contentDidChange: { [weak self] in
                    self?.onMainQueue {
                        if self?.onTheScreen ?? false {
                            self?.view?.hideEditMessageView()
                            self?.view?.hideHUD()
                            self?.view?.endUpdate()
                        }
                    }
                },
                didReceiveChange: { [weak self] change in
                    self?.onMainQueue {
                        if self?.onTheScreen ?? false {
                            self?.view?.showSending(false)
                            switch change {
                            case .update(_, let indexPath):
                                self?.view?.updateRow(at: indexPath)
                            case .insert(let object, let indexPath):
                                self?.view?.insertRow(at: indexPath)
                                if let message = object as? MessageEvent, !message.initiator.me {
                                    self?.interactor.markAsRead()
                                }
                            case .delete(let indexPath):
                                self?.view?.removeRow(at: indexPath)
                            case .move(let indexPath, let newIndexPath):
                                self?.view?.moveRow(from: indexPath, to: newIndexPath)
                            }
                        }
                    }
                }
            )
        )
    }

    func viewDidAppear() {
        if appearedMoreThanOnce {
            refreshUI(includingMessages: true)
        }
        onTheScreen = true
        interactor.markAsRead()
    }
    
    func viewWillDisappear() {
        appearedMoreThanOnce = true
        onTheScreen = false
    }
    
    func rightBarButtonPressed() {
        router.showConversationInfoScreen(with: conversation)
    }
    
    func messageTextViewDidBeginEditing() {
        interactor.sendTyping()
    }
    
    func cancelEditPressed() {
        currentlyEditedMessage = nil
        view?.hideEditMessageView()
        view?.clearMessageTextView()
    }
    
    func didLongTapCell(at indexPath: IndexPath) {
        view?.deselectAllCells()
        
        guard let messageEvent = interactor.getEvent(at: indexPath) as? MessageEvent,
            !messageEvent.message.removed, let me = me else {
                return
        }
        
        // for my messages
        if messageEvent.initiator.me {
            // permissions check
            if (me.isOwner || me.permissions.canEditMessages || me.permissions.canRemoveMessages) {
                view?.selectCell(at: indexPath)
            }
        // for others messages
        } else {
            // permissions check
            if (me.isOwner || me.permissions.canEditAllMessages || me.permissions.canRemoveAllMessages) {
                view?.selectCell(at: indexPath)
            }
        }
    }
    
    func sendTouchUp(with text: String) {
        guard let view = view else { return }
        view.showSending(true)
        if let currentlyEditedMessage = currentlyEditedMessage {
            if text == currentlyEditedMessage.text {
                view.showSending(false)
                view.hideEditMessageView()
            } else {
                interactor.editMessage(with: currentlyEditedMessage.uuid, text: text)
                // Sending will be hidden after result received via presenter input
            }
        } else {
            interactor.sendMessage(with: text)
        }
    }
    
    // MARK: - ActiveConversationInteractorOutput -
    func failedToSendMessage(with error: Error) {
        onMainQueue {
            self.view?.showError(error)
            self.view?.showSending(false)
        }
    }
    
    func failedToEditMessage(with error: Error) {
        onMainQueue {
            self.view?.showError(error)
            self.currentlyEditedMessage = nil
            self.view?.showSending(false)
            self.view?.hideEditMessageView()
            self.view?.clearMessageTextView()
        }
    }
    
    func failedToRemoveMessage(with error: Error) {
        onMainQueue {
            self.view?.hideHUD()
            self.view?.showError(error)
        }
    }
    
    func conversationDisappeared() {
        onMainQueue {
            self.router.showConversationsScreen()
        }
    }
    
    func conversationChanged(_ conversation: Conversation) {
        onMainQueue {
            if self.onTheScreen {
                self.refreshUI(includingMessages: false)
            }
        }
    }
    
    func didReceiveTyping(from participant: Participant) {
        if !isShowingTyping { view?.showIsTyping(true) }
        
        typingUsersArray.append(participant.user.displayName)
        updateArray()
        
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(timerTick), userInfo: nil, repeats: false)
    }
    
    @objc private func timerTick() {
        typingUsersArray.removeFirst()
        updateArray()
    }
    
    private func updateArray() {
        guard let view = view else { return }
        
        switch typingUsersArray.count {
        case 0:
            view.showIsTyping(false)
        case 1:
            view.updateTypingLabel(with: "\(typingUsersArray[0]) is typing...")
        case 3...:
            view.updateTypingLabel(with: "\(typingUsersArray[0]) and \(typingUsersArray.count - 1) others are typing ")
        default:
            let stringFromArray = Array(Set(typingUsersArray)).joined(separator:", ")
            view.updateTypingLabel(with: "\(stringFromArray) are typing...")
        }
    }

    // MARK: - Private Methods -
    private func refreshUI(includingMessages: Bool = false) {
        guard let view = view else { return }
        
        view.hideHUD()
    
        switch type {
        case .direct:
            view.showNewMessageContainer(true)
        case .chat:
            let me = conversation.participants.first { $0.user.me }
            view.showNewMessageContainer(me?.permissions.canWrite ?? false)
        case .channel:
            let me = conversation.participants.first { $0.user.me }
            view.showNewMessageContainer(me?.isOwner ?? false)
        }
        
        view.title = conversation.title
        view.updateRightBarButtonImage(
            with: conversation.pictureName,
            and: conversation.title
        )
        
        if includingMessages {
            view.refresh()
        }
    }
}
