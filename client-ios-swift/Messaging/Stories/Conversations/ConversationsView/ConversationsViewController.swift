/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol ConversationsViewInput: AnyObject, HUDShowable, TableViewControlling {
    var showEmptiness: Bool { get set }
}

protocol ConversationsViewOutput: AnyObject, ControllerLifeCycleObserver {
    func createConversationPressed()
    func profilePressed()
    func didSelectRow(at indexPath: IndexPath)
    func getConfiguratorForCell(at indexPath: IndexPath) -> CellConfigurator
    var numberOfRows: Int { get }
}

final class ConversationsViewController:
    UIViewController,
    ConversationsViewInput,
    UITableViewDelegate,
    UITableViewDataSource
{
    var output: ConversationsViewOutput! // DI

    @IBOutlet private weak var emptyListLabel: UILabel!
    @IBOutlet private weak var conversationsTableView: ConversationsTableView!
    var tableView: UITableView { conversationsTableView }
    
    var showEmptiness: Bool {
        get { conversationsTableView.isHidden }
        set { conversationsTableView.isHidden = newValue }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        conversationsTableView.tableFooterView = UIView()
        conversationsTableView.delegate = self
        conversationsTableView.dataSource = self
        
        output?.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        output.viewWillAppear()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        output.viewDidAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        output.viewWillDisappear()
    }
    
    @IBAction private func rightBarButtonPressed(_ sender: UIBarButtonItem) {
        output?.createConversationPressed()
    }

    @IBAction private func leftBarButtonPressed(_ sender: UIBarButtonItem) {
        output?.profilePressed()
    }
    
    // MARK: - UITableViewDelegate -
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        output?.didSelectRow(at: indexPath)
    }
    
    // MARK: - UITableViewDataSource -
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       output.numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let configurator = output.getConfiguratorForCell(at: indexPath)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: type(of: configurator).reuseId, for: indexPath)
        configurator.configure(cell: cell)
        
        return cell
    }
}
