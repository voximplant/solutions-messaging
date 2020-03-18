/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class MessageTableCell: UITableViewCell, ConfigurableCell {
    typealias Model = MessageTableCellModel
    
    @IBOutlet private weak var messageContainerView: UIView!
    @IBOutlet private weak var messageTextView: UITextView!
    @IBOutlet private weak var dialogView: UIView!
    
    @IBOutlet private var messageLeftConstraint: NSLayoutConstraint!
    @IBOutlet private var messageRightConstraint: NSLayoutConstraint!
    @IBOutlet private var messageWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var nameLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var nameLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var editedLabel: UILabel!
    @IBOutlet private weak var editedLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var readImageView: UIImageView!
    @IBOutlet private weak var readImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var errorButton: RoundButton!
    
    private var dialogOutput: MessageDialogViewOutput?
    
    var messageText: String? {
        get { return messageTextView.text }
        set { messageTextView.text = newValue }
    }
    
    var isEdited: Bool = false {
        didSet {
            editedLabel.isHidden = !isEdited
            editedLabelWidthConstraint.isActive = !isEdited
        }
    }
    
    var isRead: Bool = false {
        didSet {
            readImageView.image = isRead ? #imageLiteral(resourceName: "DoubleCheck"): #imageLiteral(resourceName: "Check")
        }
    }
    
    var isMy: Bool = false {
        didSet {
            messageTextView.textColor            = isMy ? VoxColor.myMessageText           : VoxColor.messageText
            messageContainerView.backgroundColor = isMy ? VoxColor.myMessageBackground     : VoxColor.messageBackground
            editedLabel.textColor                = isMy ? VoxColor.myAdditionalMessageInfo : VoxColor.additionalMessageInfo
            timeLabel.textColor                  = isMy ? VoxColor.myAdditionalMessageInfo : VoxColor.additionalMessageInfo
            readImageView.tintColor              = isMy ? VoxColor.myAdditionalMessageInfo : VoxColor.additionalMessageInfo
            messageLeftConstraint.isActive       = !isMy
            messageRightConstraint.isActive      = isMy
            nameLabelHeightConstraint.constant   = isMy ? 0 : 17
            readImageWidthConstraint.constant    = isMy ? 24 : 0
            nameLabelWidthConstraint.isActive    = isMy
            readImageView.isHidden               = !isMy
        }
    }
    
    var isFailed: Bool = false {
        didSet {
            if isMy { messageRightConstraint.constant = isFailed ? 36 : 8 }
            errorButton.isHidden = !isMy
        }
    }
    
    private var sequence: Int = 0
    
    func configure(with model: MessageTableCellModel) {
        sequence = model.sequence
        isEdited = model.isEdited
        isMy = model.isMy
        isFailed = model.isFailed
        isRead = model.isRead
        messageText = model.text
        nameLabel.text = model.senderName
        timeLabel.text = model.time
        dialogOutput = model.dialogOutput
    }
    
    @IBAction func errorButtonPressed(_ sender: RoundButton) {
    }
    
    @IBAction func editButtonPressed(_ sender: UIButton) {
        dialogOutput?.editAction(self, sequence)
    }
    
    @IBAction func removeButtonPressed(_ sender: UIButton) {
        dialogOutput?.removeAction(self, sequence)
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        dialogOutput?.cancelAction(self, sequence)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        messageWidthConstraint.constant = UIScreen.main.bounds.width / 1.2
        messageContainerView.layer.cornerRadius = 20
        dialogView.layer.cornerRadius = 20
        messageTextView.textContainerInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0);
        transform = CGAffineTransform(rotationAngle: (-.pi)) // because chat cells are reverted
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        dialogView.isHidden = !selected
    }
}
    
fileprivate extension VoxColor {
    static var messageText: UIColor {
        if #available(iOS 13.0, *) { return UIColor.label }
        else { return .black }
    }
    static var additionalMessageInfo: UIColor {
        if #available(iOS 13.0, *) { return UIColor.tertiaryLabel }
        else { return .lightGray }
    }
    static var messageBackground: UIColor {
        if #available(iOS 13.0, *) { return UIColor.tertiarySystemGroupedBackground }
        else { return .lightGray }
    }
    static var myMessageText: UIColor { return .white }
    static var myAdditionalMessageInfo: UIColor { return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.45) }
    static var myMessageBackground: UIColor { return VoxColor.accent }
}
