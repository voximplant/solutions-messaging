/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol ActiveConversationViewInput: AnyObject, HUDShowable, TableViewControlling {
    var title: String? { get set }
    func updateRightBarButtonImage(with imageName: String?, and title: String)
    func updateTypingLabel(with text: String)
    func showIsTyping(_ show: Bool)
    
    func showActivityIndicator(_ show: Bool)
    func showNewMessageContainer(_ show: Bool)
    func configureTableView(with dataSource: UITableViewDataSource)
    func showSending(_ show: Bool)
    func showEditMessageView(with text: String)
    func fillMessageTextView(with text: String)
    func clearMessageTextView()
    func hideEditMessageView()
    func selectCell(at indexPath: IndexPath)
    func deselectAllCells()
    func scrollToBottom()
}

protocol ActiveConversationViewOutput: AnyObject, ControllerLifeCycleObserver {
    func sendTouchUp(with text: String)
    func rightBarButtonPressed()
    func cancelEditPressed()
    func messageTextViewDidBeginEditing()
    func didLongTapCell(at indexPath: IndexPath)
}

final class ActiveConversationViewController:
    UIViewController,
    ActiveConversationViewInput,
    MovingWithKeyboard,
    UITableViewDelegate,
    UITextViewDelegate
{
    var output: ActiveConversationViewOutput! // DI
    
    @IBOutlet private weak var conversationTableView: ActiveConversationTableView!
    @IBOutlet private weak var typingContainerView: UIView!
    @IBOutlet private weak var editMessageContainerView: SeparatedView!
    @IBOutlet private weak var editMessagePreviewLabel: UILabel!
    @IBOutlet private weak var editMessageHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var typingLabel: UILabel!
    @IBOutlet private weak var typingButtomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var sendButton: ButtonWithIndicator!
    @IBOutlet private weak var messageTextView: UITextView!
    @IBOutlet private weak var rightBarButtonItem: RoundBarButtonItemWithActivity!
    @IBOutlet private weak var messageContainerView: UIView!
    @IBOutlet private var longPressRecognizer: UILongPressGestureRecognizer!
    
    var tableView: UITableView { conversationTableView }
    
    // MARK: MovingWithKeyboard
    var adjusted: Bool = false
    var defaultPositionY: CGFloat = 0.0
    var moveMultiplier: CGFloat { 1 }
    var keyboardWillChangeFrameObserver: NSObjectProtocol?
    var keyboardWillHideObserver: NSObjectProtocol?
    
    private var tableDataSource: UITableViewDataSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageTextView.delegate = self
        
        // because tableView for chat is reverted
        conversationTableView.transform = CGAffineTransform(rotationAngle: (-.pi))
        messageTextView.textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        
        addBlur()
        setupNavigationBarItem()
        hideKeyboardWhenTappedAround(on: conversationTableView)
        
        rightBarButtonItem.conversationButton.addTarget(
            self,
            action: #selector(rightBarButtonPressed),
            for: .touchUpInside
        )
        
        subscribeOnKeyboardEvents()
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
        output.viewWillDisappear()
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
        let touchPoint = longPressRecognizer.location(in: conversationTableView)
        
        if let indexPath = conversationTableView.indexPathForRow(at: touchPoint) {
            output.didLongTapCell(at: indexPath)
        }
    }
    
    @IBAction func cancelEditPressed(_ sender: UIButton) {
        output.cancelEditPressed()
    }
    
    deinit {
        unsubscribeFromKeyboardEvents()
    }
    
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
        conversationTableView.delegate = self
        tableDataSource = dataSource
        conversationTableView.dataSource = tableDataSource
    }
    
    func updateRightBarButtonImage(with imageName: String?, and title: String) {
        rightBarButtonItem.profileImageView.profileName = title
        rightBarButtonItem.profileImageView.name = imageName
    }
    
    func updateTypingLabel(with text: String) {
        typingLabel.text = text
    }
    
    func showIsTyping(_ show: Bool) {
        UIView.animate(
            withDuration: 1,
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction],
            animations: { self.typingContainerView.alpha = show ? 1 : 0 },
            completion: nil
        )
    }
    
    func selectCell(at indexPath: IndexPath) {
        conversationTableView.cellForRow(at: indexPath)?.setSelected(true, animated: true)
    }
    
    func deselectAllCells() {
        conversationTableView.visibleCells.forEach {
            $0.setSelected(false, animated: false)
        }
    }
    
    func scrollToBottom() {
        conversationTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
    }
    
    func showActivityIndicator(_ show: Bool) {
        rightBarButtonItem.conversationButton.isHidden = show
        rightBarButtonItem.profileImageView.isHidden = show
        show
            ? rightBarButtonItem.activityIndicator.startAnimating()
            : rightBarButtonItem.activityIndicator.stopAnimating()
    }
    
    func showNewMessageContainer(_ show: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.messageContainerView.alpha = show ? 1 : 0
        }
    }
    
    // MARK: - UITableViewDelegate -
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 4 }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 4 }
    
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
