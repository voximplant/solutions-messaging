/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol ConversationsViewInput: AnyObject, UIIndicator {
    func refresh()
    func updateRow(at indexPath: IndexPath)
    func removeRow(at indexPath: IndexPath)
    func insertRow(at indexPath: IndexPath)
    func configureTableView(with dataSource: UITableViewDataSource)
}

protocol ConversationsViewOutput: AnyObject, ControllerLifeCycle {
    func rightBarButtonPressed()
    func leftBarButtonPressed()
    func didSelectRow(with indexPath: IndexPath)
    func didAppearAfterRemoving(conversation: Conversation)
}

final class ConversationsViewController: ViewController, ConversationsViewInput, UITableViewDelegate {
    var output: ConversationsViewOutput!

    @IBOutlet private weak var tableView: ConversationsTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    @IBAction private func rightBarButtonPressed(_ sender: UIBarButtonItem) {
        output?.rightBarButtonPressed()
    }

    @IBAction private func leftBarButtonPressed(_ sender: UIBarButtonItem) {
        output?.leftBarButtonPressed()
    }
    
    // MARK: - ConversationsViewInput -
    func configureTableView(with dataSource: UITableViewDataSource) {
        tableView.delegate = self
        tableView.dataSource = dataSource
    }
    
    func refresh() {
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    func updateRow(at indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    func removeRow(at indexPath: IndexPath) {
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    func insertRow(at indexPath: IndexPath) {
        tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    // MARK: - UITableViewDelegate -
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        output?.didSelectRow(with: indexPath)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { return UIView() }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { return 1 }
    
}
