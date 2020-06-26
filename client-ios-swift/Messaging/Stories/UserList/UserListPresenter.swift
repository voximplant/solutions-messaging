/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

enum UserListType {
    case singlePick
    case multiplePick
    case editable
}

protocol UserListInput: AnyObject {
    var selectedUserIDs: Set<User.ID> { get }
    var type: UserListType? { get set }
    func refresh()
    func cleanSelectedUsers()
}

protocol UserListOutput: AnyObject {
    var numberOfUsers: Int { get }
    func getUser(at indexPath: IndexPath) -> User
    
    func didSelectUser(at index: Int)
    func didRemoveUser(at index: Int)
    
    func subscribeOnUserChanges(_ observer: DataSourceObserver<User>)
}

extension UserListOutput {
    func didSelectUser(at index: Int) { }
    func didRemoveUser(at index: Int) { }
    func subscribeOnUserChanges(_ observer: DataSourceObserver<User>) { }
}

final class UserListPresenter: UserListViewOutput, UserListInput {
    private typealias UserCellConfigurator
        = TableCellConfigurator<UserListCell, UserListCellModel>
    
    private weak var view: UserListViewInput?
    private let userListOutput: UserListOutput
    private(set) var selectedUserIDs: Set<User.ID> = []
    var numberOfUsers: Int { userListOutput.numberOfUsers }
    var type: UserListType? {
        didSet {
            view?.allowEditing(type == .editable)
        }
    }
    
    required init(view: UserListViewInput, output: UserListOutput) {
        self.view = view
        self.userListOutput = output
    }
    
    // MARK: - UserListInput
    func refresh() {
        view?.refresh()
    }
    
    // MARK: - UserListViewOutput
    func viewDidLoad() {
        userListOutput.subscribeOnUserChanges(
            DataSourceObserver<User>(
                contentWillChange: { [weak self] in self?.view?.beginUpdate() },
                contentDidChange: { [weak self] in self?.view?.endUpdate() },
                didReceiveChange: { [weak self] change in
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
            )
        )
    }
    
    func getConfiguratorForCell(at indexPath: IndexPath) -> CellConfigurator {
        let user = userListOutput.getUser(at: indexPath)
        return UserCellConfigurator(model: user.makeCellModel(
            selectedUserIDs.contains { $0 == user.id}
        ))
    }   
    
    func didSelectUser(at indexPath: IndexPath) {
        switch type {
        case .singlePick:
            userListOutput.didSelectUser(at: indexPath.row)
        case .multiplePick:
            let user = userListOutput.getUser(at: indexPath)
            let shouldSelect = !selectedUserIDs.contains { $0 == user.id }
            if shouldSelect {
                selectedUserIDs.insert(user.id)
            } else {
                selectedUserIDs.remove(user.id)
            }
            view?.setSelected(
                shouldSelect,
                cellAt: indexPath
            )
            userListOutput.didSelectUser(at: indexPath.row)
        case .editable:
            break
        case .none:
            break
        }
    }
    
    func didDeleteUser(at indexPath: IndexPath) {
        let user = userListOutput.getUser(at: indexPath)
        selectedUserIDs.remove(user.id)
        userListOutput.didRemoveUser(at: indexPath.row)
    }
    
    func cleanSelectedUsers() {
        selectedUserIDs.removeAll()
    }
}

fileprivate extension User {
    func makeCellModel(_ choosen: Bool = false) -> UserListCellModel {
        UserListCellModel(
            displayName: displayName,
            pictureName: pictureName,
            isChoosen: choosen
        )
    }
}
