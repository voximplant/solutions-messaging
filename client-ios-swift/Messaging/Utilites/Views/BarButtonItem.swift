/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

enum BarButtonAction {
    case edit
    case save
}

final class BarButtonItem: UIBarButtonItem {
    var buttonAction: BarButtonAction? {
        didSet {
            switch buttonAction {
            case .edit:
                tintColor = VoxColor.labelColor
                title = "edit"
                isEnabled = true
            case .save:
                tintColor = VoxColor.labelColor
                title = "save"
                isEnabled = true
            case .none:
                tintColor = .clear
                title = ""
                isEnabled = false
            }
        }
    }
}

fileprivate extension VoxColor {
    static var labelColor: UIColor {
        if #available(iOS 13.0, *) { return UIColor.label }
        else { return .black }
    }
}
