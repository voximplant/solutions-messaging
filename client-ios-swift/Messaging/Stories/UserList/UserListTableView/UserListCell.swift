/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

struct UserListCellModel {
    var displayName: String
    var pictureName: String?
    var isChoosen: Bool
}

final class UserListCell: UITableViewCell, ConfigurableCell {
    @IBOutlet private weak var userPictureImageView: ProfilePictureView!
    @IBOutlet private weak var username: UILabel!
    
    var isChoosen: Bool = false {
        didSet {
            accessoryType = isChoosen ? .checkmark : .none
        }
    }
    
    func configure(with model: UserListCellModel) {
        userPictureImageView.profileName = model.displayName
        userPictureImageView.name = model.pictureName
        username.text = model.displayName
        isChoosen = model.isChoosen
    }
}

