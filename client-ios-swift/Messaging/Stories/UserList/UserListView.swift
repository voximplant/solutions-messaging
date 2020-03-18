/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol UserListViewInput: AnyObject {
    func setupTableView(with dataSource: UserListTableViewDataSource)
    func setSelected(_ selected: Bool, cellAt indexPath: IndexPath)
    func reloadTableView()
    func showActivityIndicator()
    func hideActivityIndicator()
    func allowTableViewEditing()
}

protocol UserListViewOutput: UserListInput {
    func viewDidLoad()
    func didSelectRow(at indexPath: IndexPath)
    func didEditRow(at indexPath: IndexPath)
}

final class UserListView: UIView, NibLoadable, UserListViewInput, UserListTableViewDelegate {
    var presenter: UserListViewOutput!
    
    @IBOutlet private weak var tableView: UserListTableView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
        sharedInit()
    }
    
    private func sharedInit() {
        presenter = UserListPresenter(view: self)
        presenter?.viewDidLoad()
    }
    
    // MARK: - UserListViewInput
    func setSelected(_ selected: Bool, cellAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath)
        { cell.isChoosen = selected }
    }
    
    func setupTableView(with dataSource: UserListTableViewDataSource) {
        tableView.delegate = self
        tableView.dataSource = dataSource
    }
    
    func reloadTableView() {
        DispatchQueue.main.async { self.tableView.reloadData() }
    }
    
    func showActivityIndicator() {
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
    }
    
    func hideActivityIndicator() {
        activityIndicatorView.stopAnimating()
    }
    
    func allowTableViewEditing() { tableView.allowsEditing = true }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presenter?.didSelectRow(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        1   
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    
    func didDeleteRow(at indexPath: IndexPath) {
         presenter.didEditRow(at: indexPath)
    }
}

extension UserListTableView {
    override func cellForRow(at indexPath: IndexPath) -> UserListCell? {
        if let cell = super.cellForRow(at: indexPath) as? UserListCell { return cell }
        else { return nil }
    }
}
