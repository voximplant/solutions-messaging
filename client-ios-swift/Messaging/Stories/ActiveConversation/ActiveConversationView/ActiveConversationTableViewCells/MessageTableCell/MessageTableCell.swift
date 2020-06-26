/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class MessageTableCell: UITableViewCell, ConfigurableCell {
    @IBOutlet private weak var messageContainerView: UIView!
    @IBOutlet private weak var messageTextView: UITextView!
    @IBOutlet private weak var dialogView: UIView!
    @IBOutlet private weak var editButton: UIButton!
    @IBOutlet private weak var removeButton: UIButton!
    
    @IBOutlet private var messageLeftConstraint: NSLayoutConstraint!
    @IBOutlet private var messageRightConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var editedLabel: UILabel!
    @IBOutlet private weak var editedLabelWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var readImageView: UIImageView!
    @IBOutlet private weak var readImageWidthConstraint: NSLayoutConstraint!
    
    private var output: MessageTableCellModel.MessageTableCellOutput?
    
    private var model: MessageTableCellModel!
    
    func configure(with model: MessageTableCellModel) {
        self.model = model
        
        messageLeftConstraint.isActive = !model.isMy
        messageRightConstraint.isActive = model.isMy
        
        switch model.messageState {
        case .normal:
            editedLabel.isHidden = true
            editedLabelWidthConstraint.isActive = false
            readImageView.image = model.isRead ? #imageLiteral(resourceName: "DoubleCheck") : #imageLiteral(resourceName: "Check")
            readImageView.isHidden = !model.isMy
            readImageView.tintColor = model.isMy
                ? VoxColor.myAdditionalMessageInfo
                : VoxColor.additionalMessageInfo
            editButton.isHidden = !model.editingAllowed
            removeButton.isHidden = !model.removingAllowed
            readImageWidthConstraint.constant = model.isMy ? 24 : 0
        case .edited:
            editedLabel.isHidden = false
            editedLabel.textColor = model.isMy
                ? VoxColor.myAdditionalMessageInfo
                : VoxColor.additionalMessageInfo
            editedLabelWidthConstraint.isActive = true
            readImageView.image = model.isRead ? #imageLiteral(resourceName: "DoubleCheck") : #imageLiteral(resourceName: "Check")
            readImageView.isHidden = !model.isMy
            readImageView.tintColor = model.isMy
                ? VoxColor.myAdditionalMessageInfo
                : VoxColor.additionalMessageInfo
            editButton.isHidden = !model.editingAllowed
            removeButton.isHidden = !model.removingAllowed
            readImageWidthConstraint.constant = model.isMy ? 24 : 0
        case .removed:
            editedLabel.isHidden = true
            editedLabelWidthConstraint.isActive = false
            readImageView.isHidden = true
            readImageWidthConstraint.constant = 0
        }
        
        messageTextView.textColor = model.isMy
            ? VoxColor.myMessageText
            : VoxColor.messageText
        messageContainerView.backgroundColor = model.isMy
            ? VoxColor.myMessageBackground
            : VoxColor.messageBackground
        timeLabel.textColor = model.isMy
            ? VoxColor.myAdditionalMessageInfo
            : VoxColor.additionalMessageInfo
        
        messageTextView.text = model.text
        nameLabel.text = model.isMy ? nil :  model.name
        timeLabel.text = model.time
        
        output = model.output
    }
    
    @IBAction func editButtonPressed(_ sender: UIButton) {
        weak var weakSelf = self
        if let self = weakSelf {
            output?.editMessage(self, model)
        }
    }
    
    @IBAction func removeButtonPressed(_ sender: UIButton) {
        weak var weakSelf = self
        if let self = weakSelf {
            output?.removeMessage(self, model)
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        weak var weakSelf = self
        if let self = weakSelf {
            output?.closeOptions(self, model)
        }
    }
    
    deinit {
        output = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
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
