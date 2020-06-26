/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

struct ConversationTableCellModel {
    var type: Conversation.ConversationType
    var title: String
    var pictureName: String?
}

final class ConversationTableCell: UITableViewCell, ConfigurableCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var pictureImageView: ProfilePictureView!
    @IBOutlet private weak var conversationTypeImageView: UIImageView!
    @IBOutlet private weak var conversationTypeContainer: RoundView!
    
    func configure(with model: ConversationTableCellModel) {
        switch model.type {
        case .direct:
            conversationTypeContainer.isHidden = true
        case .channel:
            conversationTypeImageView.image = #imageLiteral(resourceName: "Bullhorn")
            conversationTypeContainer.isHidden = false
        case .chat:
            conversationTypeImageView.image = #imageLiteral(resourceName: "people")
            conversationTypeContainer.isHidden = false
        }
        titleLabel.text = model.title
        pictureImageView.profileName = model.title
        pictureImageView.name = model.pictureName
    }
}
