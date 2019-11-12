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
    var userListModelArray: [UserListCellModel] { get }
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

class UserListPresenter: UserListViewOutput {
    weak var view: UserListViewInput?
    
    weak var userListOutput: UserListOutput?
    var type: UserListType! {
        didSet {
            if type == .editable { view?.allowTableViewEditing() }
        }
    }
    
    private let dataSource: TableViewDataSource<UserListCellModel> = UserListTableViewDataSource.make(for: [])
    var userListModelArray: [UserListCellModel] {
        get { return dataSource.models }
        set { dataSource.models = newValue }
    }
    
    required init(view: UserListViewInput) { self.view = view }
    
    // MARK: - UserListInput
    func updateList(with cellModelArray: [UserListCellModel]) {
        guard let view = view else { return }
        userListModelArray = cellModelArray
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
        if userListModelArray.isEmpty { return }
        switch type {
        case .singlePick:
            userListOutput?.didSelectUser(with: indexPath.row)
        case .multiplePick:
            userListModelArray[indexPath.row].isChoosen.toggle()
            view.setSelected(userListModelArray[indexPath.row].isChoosen, cellAt: indexPath)
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
