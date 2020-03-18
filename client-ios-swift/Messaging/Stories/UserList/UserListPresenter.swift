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
    var userListOutput: UserListOutput? { get set }
    var type: UserListType! { get set }
    var userListModels: [UserListCellModel] { get }
    func updateList(with cellModelArray: [UserListCellModel])
}

protocol UserListOutput: AnyObject {
    var userListInput: UserListInput! { get set }
    func didSelectUser(with index: Int)
    func didRemoveUser(with index: Int)
    func didUpdateList(with modelArray: [UserListCellModel])
}

extension UserListOutput {
    func didSelectUser(with index: Int) { }
    func didRemoveUser(with index: Int) { }
    func didUpdateList(with modelArray: [UserListCellModel]) { }
}

fileprivate typealias UserCellConfigurator = TableCellConfigurator<UserListCell, UserListCellModel>

final class UserListPresenter: UserListViewOutput {
    weak var view: UserListViewInput?
    
    weak var userListOutput: UserListOutput?
    var type: UserListType! {
        didSet {
            if type == .editable { view?.allowTableViewEditing() }
        }
    }
    
    private let dataSource: UserListTableViewDataSource = UserListTableViewDataSource(items: [])
    private var userListConfigurators: [[UserCellConfigurator]] {
        get { dataSource.items as! [[UserCellConfigurator]] }
        set { dataSource.items = newValue }
    }
    
    private(set) var userListModels: [UserListCellModel] {
        get { userListConfigurators.first?.map { $0.model } ?? [] }
        set { userListConfigurators = [newValue.map { UserCellConfigurator(model: $0) }] }
    }
    
    required init(view: UserListViewInput) { self.view = view }
    
    // MARK: - UserListInput
    func updateList(with cellModelArray: [UserListCellModel]) {
        guard let view = view else { return }
        userListConfigurators = [cellModelArray.map { UserCellConfigurator(model: $0) }]
        view.reloadTableView()
        view.hideActivityIndicator()
        userListOutput?.didUpdateList(with: cellModelArray)
    }
    
    // MARK: - UserListViewOutput
    func viewDidLoad() {
        view?.setupTableView(with: dataSource)
        view?.showActivityIndicator()
    }
    
    func didSelectRow(at indexPath: IndexPath) {
        guard let view = view else { return }
        if userListConfigurators.isEmpty { return }
        switch type {
        case .singlePick:
            userListOutput?.didSelectUser(with: indexPath.row)
        case .multiplePick:
            userListModels[indexPath.row].isChoosen.toggle()
            view.setSelected(userListModels[indexPath.row].isChoosen, cellAt: indexPath)
            userListOutput?.didSelectUser(with: indexPath.row)
        case .editable:
            break
        case .none:
            break
        }
    }
    
    func didEditRow(at indexPath: IndexPath) {
        userListOutput?.didRemoveUser(with: indexPath.row)
    }
}
