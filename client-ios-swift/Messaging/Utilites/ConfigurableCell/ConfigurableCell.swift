/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

protocol ConfigurableCell {
    associatedtype Model
    func configure(with model: Model)
}
