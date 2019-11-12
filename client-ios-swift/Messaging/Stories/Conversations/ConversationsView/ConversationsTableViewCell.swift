/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

struct ConversationCellModel {
    var type: ConversationType
    var title: String
    var pictureName: String?
}

class ConversationsTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var pictureImageView: ProfilePictureView!
    @IBOutlet private weak var conversationTypeImageView: UIImageView!
    @IBOutlet private weak var conversationTypeContainer: RoundView!
    
    var model: ConversationCellModel! {
        didSet {
            type = model.type
            titleLabel.text = model.title
            pictureImageView.profileName = model.title
            pictureImageView.name = model.pictureName
        }
    }
    
    private var type: ConversationType? {
        didSet {
            guard let type = type else { return }
            switch type {
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
        }
    }

}
