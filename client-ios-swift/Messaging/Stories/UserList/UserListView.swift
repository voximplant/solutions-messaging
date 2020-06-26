/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol UserListViewInput: AnyObject, TableViewControlling {
    func setSelected(_ selected: Bool, cellAt indexPath: IndexPath)
    func allowEditing(_ allow: Bool)
}

protocol UserListViewOutput {
    var numberOfUsers: Int { get }
    func getConfiguratorForCell(at indexPath: IndexPath) -> CellConfigurator
    func viewDidLoad()
    func didSelectUser(at indexPath: IndexPath)
    func didDeleteUser(at indexPath: IndexPath)
}

final class UserListView:
    UIView,
    NibLoadable,
    UserListViewInput,
    UserListTableViewDelegate,
    UITableViewDataSource
{
    var output: UserListViewOutput! { // DI
        didSet {
            userTableView.delegate = self
            userTableView.dataSource = self
        }
    }
    
    @IBOutlet private weak var userTableView: UserListTableView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    
    private var isEditingAllowed: Bool { userTableView.allowsEditing }
    var tableView: UITableView { userTableView }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        setupFromNib()
        userTableView.tableFooterView = UIView()
        output?.viewDidLoad()
    }
    
    // MARK: - UserListViewInput
    func setSelected(_ selected: Bool, cellAt indexPath: IndexPath) {
        if let cell = userTableView.cellForRow(at: indexPath) as? UserListCell {
            cell.isChoosen = selected
        }
    }
    
    func showLoading(_ show: Bool) {
        if show {
            activityIndicatorView.isHidden = false
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
    }
    
    func allowEditing(_ allow: Bool) {
        userTableView.allowsEditing = allow
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        output?.didSelectUser(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    
    func didDeleteUser(at indexPath: IndexPath) {
        output.didDeleteUser(at: indexPath)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        output.numberOfUsers
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let configurator = output.getConfiguratorForCell(at: indexPath)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: type(of: configurator).reuseId, for: indexPath)
        configurator.configure(cell: cell)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        isEditingAllowed
    }
    
    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            if let tableView = tableView as? UserListTableView {
                tableView.delegateInterceptor?.didDeleteUser(at: indexPath)
            }
        }
    }
}
