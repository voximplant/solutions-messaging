/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

struct ConversationTableCellModel {
    var type: ConversationType
    var title: String
    var pictureName: String?
}

final class ConversationTableCell: UITableViewCell, ConfigurableCell {
    typealias Model = ConversationTableCellModel
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var pictureImageView: ProfilePictureView!
    @IBOutlet private weak var conversationTypeImageView: UIImageView!
    @IBOutlet private weak var conversationTypeContainer: RoundView!
    
    func configure(with model: Model) {
        switch model.type {
        case .direct:
            pictureImageView.isForUser = true
            conversationTypeContainer.isHidden = true
        case .channel:
            pictureImageView.isForUser = false
            conversationTypeImageView.image = #imageLiteral(resourceName: "Bullhorn")
            conversationTypeContainer.isHidden = false
        case .chat:
            pictureImageView.isForUser = false
            conversationTypeImageView.image = #imageLiteral(resourceName: "people")
            conversationTypeContainer.isHidden = false
        }
        titleLabel.text = model.title
        pictureImageView.profileName = model.title
        pictureImageView.name = model.pictureName
    }
}
