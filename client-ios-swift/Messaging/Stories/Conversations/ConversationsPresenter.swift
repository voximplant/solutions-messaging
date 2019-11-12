/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

class ConversationsPresenter: Presenter, ConversationsViewOutput, ConversationsInteractorOutput {
    private weak var view: ConversationsViewInput?
    
    var interactor: ConversationsInteractorInput!
    var router: ConversationsRouterInput!
    
    private let dataSource: TableViewDataSource<ConversationCellModel> = .make(for: [])
    private var cellModels: [ConversationCellModel] {
        get { return dataSource.models }
        set { dataSource.models = newValue }
    }
    
    private var conversations: [Conversation] = [] {
        didSet {
            conversations.sort { $0.lastUpdated > $1.lastUpdated }
            cellModels = conversations.map { buildCellModel(from: $0) }
        }
    }
    
    required init(view: ConversationsViewInput) { self.view = view }
    
    // MARK: - ConversationsViewOutput -
    override func viewDidLoad() {
        guard let view = view else { return }
        
        view.showHUD(with: "Connecting...")
        interactor.loginWithAccessToken()
        
        view.configureTableView(with: dataSource)
    }
    
    override func viewWillAppear() {        
        interactor.setupDelegates()
    }
    
    override func viewDidAppear() {
        guard let view = view else { return }
        guard interactor.me != nil else { return }
        
        view.showHUD(with: "Updating...")
        interactor.fetchConversations()
    }
    
    func didAppearAfterRemoving(conversation: Conversation) {
        guard let view = view else { return }
        
        if let index = conversations.firstIndex(where: { $0.uuid == conversation.uuid }) {
            conversations.remove(at: index)
            view.removeRow(at: IndexPath(row: index, section: 0))
        }
    }
    
    func rightBarButtonPressed() {
        router.showNewConversationScreen()
    }
    
    func leftBarButtonPressed() {
        router.showSettingsScreen()
    }
    
    func didSelectRow(with indexPath: IndexPath) {
        if !conversations.indices.contains(indexPath.row) { return }
        router.showActiveConversationScreen(with: conversations[indexPath.row])
    }
    
    // MARK: - ConversationsInteractorOutput -
    // MARK: - Conversation
    func didCreate(conversation: Conversation) {
        guard let view = view else { return }
        
        conversations.append(conversation)
        view.insertRow(at: IndexPath(row: 0, section: 0))
    }
    
    func beenRemoved(from conversation: Conversation) {
        guard let view = view else { return }
        
        if let index = conversations.firstIndex(where: { $0.uuid == conversation.uuid }) {
            conversations.remove(at: index)
            view.removeRow(at: IndexPath(row: index, section: 0))
        }
    }
    
    func didUpdate(conversation: Conversation) {
        guard let view = view else { return }
        
        if let index = conversations.firstIndex(where: { $0.uuid == conversation.uuid }) {
            conversations[index] = conversation
            view.updateRow(at: IndexPath(row: index, section: 0))
        } else {
            conversations.append(conversation)
            view.insertRow(at: IndexPath(row: 0, section: 0))
        }
    }
    
    func didReceive(conversations: [Conversation]) {
        guard let view = view else { return }
        
        conversations.forEach { conversation in
            if let index = self.conversations.firstIndex(where: { $0.uuid == conversation.uuid }) {
                self.conversations[index] = conversation
            } else {
                self.conversations.append(conversation)
            }
        }
        
        view.refresh()
        view.hideHUD()
    }
    
    func didRemove(conversation: Conversation) {
        guard let view = view else { return }
        
        if let index = conversations.firstIndex(where: { $0.uuid == conversation.uuid }) {
            conversations.remove(at: index)
            view.removeRow(at: IndexPath(row: index, section: 0))
        }
    }
    
    func fetchingFailed(with error: Error) {
        view?.hideHUD()
        view?.showError(with: error.localizedDescription)
    }
    
    // MARK: - Message
    func didReceive(messageEvent event: MessageEvent) {
        guard let view = view else { return }
        
        if let index = conversations.firstIndex(where: { $0.uuid == event.message.conversation }) {
            conversations[index].lastUpdated = event.timestamp
            conversations.sort { $0.lastUpdated > $1.lastUpdated }
            cellModels = conversations.map { buildCellModel(from: $0) }
            view.refresh()
        }
    }
    
    // MARK: - Connection
    override func loginCompleted() {
        guard let view = view else { return }
        
        view.showHUD(with: "Updating...")
        interactor.fetchConversations()
    }
    
    override func loginFailed(with error: Error) {
        guard let view = view else { return }
        
        view.hideHUD()
        view.showError(with: error.localizedDescription)
        router.showLoginStory()
    }
    
    override func connectionLost() {
        view?.showHUD(with: "Connection lost")
    }
    
    override func tryingToLogin() {
        view?.showHUD(with: "Connecting...")
    }
    
    // MARK: - Private Methods -
    private func buildCellModel(from conversation: Conversation) -> ConversationCellModel {
        return ConversationCellModel(type: conversation.type, title: buildTitle(for: conversation),
                                     pictureName: buildPictureName(for: conversation))
    }
    
    private func buildTitle(for conversation: Conversation) -> String {
        if conversation.type == .direct
        {
            var displayName: String = ""
            conversation.participants.forEach
                { participant in
                    if participant.user.imID != interactor.me!.imID
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
                    if participant.user.imID != interactor.me!.imID
                    { pictureName = participant.user.pictureName }
                }
            return pictureName
        }
        else { return conversation.pictureName }
    }
}
