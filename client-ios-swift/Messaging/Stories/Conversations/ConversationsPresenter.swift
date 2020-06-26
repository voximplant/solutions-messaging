/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import Foundation

final class ConversationsPresenter:
    ControllerLifeCycleObserver,
    ConversationsViewOutput,
    ConversationsInteractorOutput,
    MainQueuePerformable
{
    private typealias ConversationsCellConfigurator
        = TableCellConfigurator<ConversationTableCell, ConversationTableCellModel>
    
    private weak var view: ConversationsViewInput?
    var interactor: ConversationsInteractorInput! // DI
    var router: ConversationsRouterInput! // DI
    
    private var appearedMoreThanOnce: Bool = false
    private var onTheScreen: Bool = false
    
    init(view: ConversationsViewInput) { self.view = view }
    
    // MARK: - ConversationsViewOutput -
    var numberOfRows: Int {     
        let number = interactor.numberOfConversations
        view?.showEmptiness = number == 0
        return number
    }
    
    func viewWillAppear() {
        interactor.setupObservers(
            DataSourceObserver<Conversation>(
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
                            self?.view?.endUpdate()
                        }
                    }
                },
                didReceiveChange: { [weak self] change in
                    self?.onMainQueue {
                        if self?.onTheScreen ?? false {
                            switch change {
                            case .update(_, let indexPath):
                                self?.view?.updateRow(at: indexPath)
                            case .insert(_, let indexPath):
                                self?.view?.insertRow(at: indexPath)
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
            view?.refresh()
        }
        onTheScreen = true
    }
    
    func viewWillDisappear() {
        appearedMoreThanOnce = true
        onTheScreen = false
    }
        
    func getConfiguratorForCell(at indexPath: IndexPath) -> CellConfigurator {
        ConversationsCellConfigurator(model: interactor.getConversation(at: indexPath).cellModel)
    }
        
    func createConversationPressed() {
        router.showNewConversationScreen()
    }
    
    func profilePressed() {
        router.showSettingsScreen()
    }
    
    func didSelectRow(at indexPath: IndexPath) {
        router.showActiveConversationScreen(with: interactor.getConversation(at: indexPath))
    }
    
    // MARK: - ConversationsInteractorOutput -
    func fetchingFailed(with error: Error) {
        view?.hideHUD()
        view?.showError(error)
    }
}

fileprivate extension Conversation {
    var cellModel: ConversationTableCellModel {
        return ConversationTableCellModel(
            type: type,
            title: title,
            pictureName: pictureName
        )
    }
}
