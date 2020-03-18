/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol PermissionsViewInput: AnyObject, UIIndicator {
    func setupTableView(with dataSource: UITableViewDataSource)
    func showSaveButton(_ show: Bool)
    func reloadUI()
    func getIndexPath(for cell: PermissionsTableViewCell) -> IndexPath?
}

protocol PermissionsViewOutput: AnyObject, ControllerLifeCycle {
    func barButtonPressed()
}

final class PermissionsViewController: ViewController, PermissionsViewInput, UITableViewDelegate {
    var output: PermissionsViewOutput!
    
    @IBOutlet private weak var saveButton: BarButtonItem!
    @IBOutlet private weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        saveButton.buttonAction = .none
        output.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        output.viewWillAppear()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        output.viewDidAppear()
    }
    
    @IBAction func saveButtonPressed(_ sender: BarButtonItem) {
        output.barButtonPressed()
    }
    
    // MARK: - PermissionsViewInput
    func showSaveButton(_ show: Bool) {
        saveButton.buttonAction = show ? .save : .none
    }
    
    func setupTableView(with dataSource: UITableViewDataSource) {
        tableView.delegate = self
        tableView.dataSource = dataSource
    }
    
    func reloadUI() { tableView.reloadData() }
    
    func getIndexPath(for cell: PermissionsTableViewCell) -> IndexPath? {
        tableView.indexPath(for: cell)
    }
    
    // MARK: - UITableViewDelegates
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        1
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }
}
