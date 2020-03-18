/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol CellConfigurator {
    static var reuseId: String { get }
    func configure(cell: UIView)
}
