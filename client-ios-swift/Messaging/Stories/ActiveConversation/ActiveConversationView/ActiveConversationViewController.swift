/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol ActiveConversationViewInput: AnyObject, UIIndicator {
    func updateTitle(with text: String)
    func updateRightBarButtonImage(with imageName: String?, and title: String)
    func updateTypingLabel(with text: String)
    func showIsTyping(_ show: Bool)
    func updateTableView()
    func insertCell(at indexPath: IndexPath)
    func setReadOnCell(at indexPath: IndexPath)
    func removeCell(at indexPath: IndexPath)
    func showEditedCell(at indexPath: IndexPath, with text: String)
    func showActivityIndicator(_ show: Bool)
    func showNewMessageContainer(_ show: Bool)
    func configureTableView(with dataSource: UITableViewDataSource)
    func configureTextView()
    func showSending(_ show: Bool)
    func showEditMessageView(with text: String)
    func fillMessageTextView(with text: String)
    func clearMessageTextView()
    func hideEditMessageView()
    func selectCell(at indexPath: IndexPath)
    func deselectAllCells()
    func scrollToBottom()

}

protocol ActiveConversationViewOutput: AnyObject, ControllerLifeCycle {
    func sendTouchUp(with text: String)
    func rightBarButtonPressed()
    func cancelEditPressed()
    func messageTextViewDidBeginEditing()
    func didAppearAfterEditing(with conversationModel: Conversation)
    func didLongTapCell(at indexPath: IndexPath)
}

final class ActiveConversationViewController:
    ViewController,
    ActiveConversationViewInput,
    UITableViewDelegate,
    UITextViewDelegate
{
    var output: ActiveConversationViewOutput!
    
    @IBOutlet private weak var messagesTableView: ActiveConversationTableView!
    @IBOutlet private weak var typingContainerView: UIView!
    @IBOutlet private weak var editMessageContainerView: SeparatedView!
    @IBOutlet private weak var editMessagePreviewLabel: UILabel!
    @IBOutlet private weak var editMessageHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var typingLabel: UILabel!
    @IBOutlet private weak var typingButtomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var sendButton: ButtonWithIndicator!
    @IBOutlet private weak var messageTextView: UITextView!
    @IBOutlet private weak var rightBarButtonItem: RoundBarButtonItemWithActivity!
    @IBOutlet private weak var newMessageContainerView: UIView!
    @IBOutlet private weak var bottomSafeAreaView: UIView!
    @IBOutlet private weak var messageBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var safeAreaBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var longPressRecognizer: UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesTableView.transform = CGAffineTransform(rotationAngle: (-.pi)) // because tableView for chat is reverted
        messageTextView.textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        
        addBlur()
        setupNavigationBarItem()
        hideKeyboardWhenTappedAround(on: messagesTableView)
        moveViewWithKeyboard()
        
        rightBarButtonItem.conversationButton.addTarget(self, action: #selector(rightBarButtonPressed), for: .touchUpInside)
        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    override func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                if #available(iOS 11.0, *) {
                    self.view.frame.origin.y -= keyboardSize.height - (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0)
                }
                else {
                    self.view.frame.origin.y -= keyboardSize.height
                }
            }
        }
    }
    
    @objc func rightBarButtonPressed() {
        if !rightBarButtonItem.activityIndicator.isAnimating {
            output.rightBarButtonPressed()
        }
    }
    
    @IBAction func sendbuttonPressed(_ sender: Any) {
        guard let text = messageTextView.text else { return }
        
        if text.isEmpty || text == "" { return }
        output.sendTouchUp(with: text)
        messageTextView.text = ""
    }
    
    @IBAction func didRecognizeLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state != .began { return }
        let touchPoint = longPressRecognizer.location(in: messagesTableView)
        
        if let indexPath = messagesTableView.indexPathForRow(at: touchPoint) {
            output.didLongTapCell(at: indexPath)
        }
    }
    
    @IBAction func cancelEditPressed(_ sender: UIButton) {
        output.cancelEditPressed()
    }
    
    deinit { removeKeyboardObservers() }
    
    // MARK: - ActiveConversationViewInput -
    func showSending(_ show: Bool) {
        sendButton.showLoading(show)
    }
    
    func showEditMessageView(with text: String) {
        editMessagePreviewLabel.text = text
        UIView.animate(withDuration: 0.2) {
            self.editMessageContainerView.alpha = 1
            self.editMessageHeightConstraint.constant = 30
        }
    }
    
    func fillMessageTextView(with text: String) {
        messageTextView.text = text
    }
    
    func clearMessageTextView() {
        messageTextView.text = nil
    }
    
    func hideEditMessageView() {
        UIView.animate(withDuration: 0.2) {
            self.editMessageHeightConstraint.constant = 0
            self.editMessageContainerView.alpha = 0
        }
    }
    
    func configureTableView(with dataSource: UITableViewDataSource) {
        messagesTableView.delegate = self
        messagesTableView.dataSource = dataSource
    }
    
    func configureTextView() { messageTextView.delegate = self }
    
    func updateTitle(with text: String) { title = text }
    
    func updateRightBarButtonImage(with imageName: String?, and title: String) {
        rightBarButtonItem.profileImageView.profileName = title
        rightBarButtonItem.profileImageView.name = imageName
    }
    
    func updateTypingLabel(with text: String) { self.typingLabel.text = text }
    
    func showIsTyping(_ show: Bool) {
        UIView.animate(withDuration: 1, delay: 0, options: [.curveEaseInOut, .allowUserInteraction],
                       animations: { self.typingContainerView.alpha = show ? 1 : 0 }, completion: nil)
    }
    
    func setReadOnCell(at indexPath: IndexPath) {
        guard let cell = messagesTableView.cellForRow(at: indexPath)
            else {
                return
        }
        
        if let cell = cell as? MessageTableCell {
            cell.isRead = true
        }
    }
    
    func selectCell(at indexPath: IndexPath) {
        messagesTableView.cellForRow(at: indexPath)?.setSelected(true, animated: true)
    }
    
    func deselectAllCells() {
        messagesTableView.visibleCells.forEach {
            $0.setSelected(false, animated: false)
        }
    }
    
    func showEditedCell(at indexPath: IndexPath, with text: String) {
        if let cell = messagesTableView.cellForRow(at: indexPath) as? MessageTableCell {
            cell.isEdited = true
            cell.messageText = text
        }
    }
    
    func removeCell(at indexPath: IndexPath) {
        messagesTableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    func updateTableView() {
        if messagesTableView.numberOfSections > 0 {
            messagesTableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        } else {
            messagesTableView.reloadData()
        }
    }
    
    func insertCell(at indexPath: IndexPath) {
        messagesTableView.insertRows(at: [indexPath], with: .top)
    }
    
    func scrollToBottom() {
        messagesTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
    }
    func showActivityIndicator(_ show: Bool) {
        rightBarButtonItem.conversationButton.isHidden = show
        rightBarButtonItem.profileImageView.isHidden = show
        show ? rightBarButtonItem.activityIndicator.startAnimating()
             : rightBarButtonItem.activityIndicator.stopAnimating()
    }
    
    func showNewMessageContainer(_ show: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.bottomSafeAreaView.alpha = show ? 1 : 0
            self.newMessageContainerView.alpha = show ? 1 : 0
            self.messageBarHeightConstraint.constant = show ? 52 : 0
            var additionalInset: CGFloat = 0.0
            if #available(iOS 11.0, *)
            { additionalInset = self.view.safeAreaInsets.bottom }
            self.safeAreaBarHeightConstraint.constant = show ? additionalInset : 0
        }
    }
    
    // MARK: - UITableViewDelegate -
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { return 4 }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return 4 }
    
    // MARK: - UITextViewDelegate -
    func textViewDidBeginEditing(_ textView: UITextView) {
        output.messageTextViewDidBeginEditing()
    }
    
    // MARK: - Private Methods -
    private func addBlur() {
        var blurEffect = UIBlurEffect()
        if #available(iOS 10.0, *) { blurEffect = UIBlurEffect(style: UIBlurEffect.Style.prominent) }
        else { blurEffect = UIBlurEffect(style: UIBlurEffect.Style.extraLight) }
        
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.alpha = 0.7
        blurEffectView.frame = typingContainerView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        typingContainerView.addSubview(blurEffectView)
        typingContainerView.sendSubviewToBack(blurEffectView)
    }
    
    private func setupNavigationBarItem() {
        navigationItem.setRightBarButton(rightBarButtonItem, animated: false)
    }
}
