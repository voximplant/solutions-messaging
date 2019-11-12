/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol MessageTableViewCellDelegate: AnyObject {
    func editButtonPressed(on cell: MessageTableViewCell, with sequence: Int)
    func removeButtonPressed(on cell: MessageTableViewCell, with sequence: Int)
    func cancelButtonPressed(on cell: MessageTableViewCell)
}

class MessageTableViewCell: UITableViewCell {
    weak var delegate: MessageTableViewCellDelegate?
    
    @IBOutlet private weak var eventContainerView: UIView!
    @IBOutlet private weak var eventLabel: UILabel!
    
    @IBOutlet private weak var messageContainerView: UIView!
    @IBOutlet private weak var messageTextView: UITextView!
    @IBOutlet private weak var dialogView: UIView!
    
    @IBOutlet private var messageLeftConstraint: NSLayoutConstraint!
    @IBOutlet private var messageRightConstraint: NSLayoutConstraint!
    @IBOutlet private var messageWidthConstraint: NSLayoutConstraint!
    @IBOutlet private var messageHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var nameLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var nameLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var editedLabel: UILabel!
    @IBOutlet private weak var editedLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var readImageView: UIImageView!
    @IBOutlet private weak var readImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var errorButton: RoundButton!
    
    var model: MessengerCellModel! {
        didSet {
            switch model {
            case .message(let messageModel):
                isEvent = false
                isEdited = messageModel.isEdited
                isMy = messageModel.isMy
                isFailed = messageModel.isFailed
                isRead = messageModel.isRead
                messageText = messageModel.text
                nameLabel.text = messageModel.senderName
                timeLabel.text = messageModel.time
            case .event(let eventModel):
                dialogView.isHidden = true
                isEvent = true
                eventLabel.text = eventModel.text
            case .none:
                fatalError()
            }
            isInEditMode = false
        }
    }
    
    var isEvent: Bool = false {
        didSet {
            messageHeightConstraint.isActive = isEvent
            messageContainerView.isHidden = isEvent
            eventContainerView.isHidden = !isEvent
        }
    }
    
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
    
    var isInEditMode: Bool = false {
        didSet {
            dialogView.isHidden = !isInEditMode
        }
    }
    
    var isRead: Bool = false {
        didSet {
            readImageView.image = isRead ? #imageLiteral(resourceName: "DoubleCheck"): #imageLiteral(resourceName: "Check")
        }
    }
    
    var isMy: Bool = false {
        didSet {
            if !isEvent {
                messageTextView.textColor            = isMy ? VoxColor.myMessageText           : VoxColor.messageText
                messageContainerView.backgroundColor = isMy ? VoxColor.myMessageBackground     : VoxColor.messageBackground
                editedLabel.textColor                = isMy ? VoxColor.myAdditionalMessageInfo : VoxColor.additionalMessageInfo
                timeLabel.textColor                  = isMy ? VoxColor.myAdditionalMessageInfo : VoxColor.additionalMessageInfo
                readImageView.tintColor              = isMy ? VoxColor.myAdditionalMessageInfo : VoxColor.additionalMessageInfo
                messageLeftConstraint.isActive       = isMy ? false                            : true
                messageRightConstraint.isActive      = isMy ? true                             : false
                nameLabelHeightConstraint.constant   = isMy ? 0                                : 17
                readImageWidthConstraint.constant    = isMy ? 24                               : 0
                nameLabelWidthConstraint.isActive    = isMy
                readImageView.isHidden               = !isMy
            }
        }
    }
    
    var isFailed: Bool = false {
        didSet {
            if isMy { messageRightConstraint.constant = isFailed ? 36 : 8 }
            errorButton.isHidden = !isMy
        }
    }
    
    @IBAction func errorButtonPressed(_ sender: RoundButton) {
    }
    
    @IBAction func editButtonPressed(_ sender: UIButton) {
        delegate?.editButtonPressed(on: self, with: model.sequence)
    }
    
    @IBAction func removeButtonPressed(_ sender: UIButton) {
        delegate?.removeButtonPressed(on: self, with: model.sequence)
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        delegate?.cancelButtonPressed(on: self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        messageWidthConstraint.constant = UIScreen.main.bounds.width / 1.2
        messageContainerView.layer.cornerRadius = 20
        dialogView.layer.cornerRadius = 20
        messageTextView.textContainerInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0);
        transform = CGAffineTransform(rotationAngle: (-.pi)) // because chat cells are reverted
    }
}
    
fileprivate extension VoxColor {
    class var messageText: UIColor {
        if #available(iOS 13.0, *) { return UIColor.label }
        else { return .black }
    }
    class var additionalMessageInfo: UIColor {
        if #available(iOS 13.0, *) { return UIColor.tertiaryLabel }
        else { return .lightGray }
    }
    class var messageBackground: UIColor {
        if #available(iOS 13.0, *) { return UIColor.tertiarySystemGroupedBackground }
        else { return .lightGray }
    }
    class var myMessageText: UIColor { return .white }
    class var myAdditionalMessageInfo: UIColor { return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.45) }
    class var myMessageBackground: UIColor { return VoxColor.accent }
}
