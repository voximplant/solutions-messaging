/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

typealias Index = Int

enum Picture: String {
    case picture1 = "1"
    case picture2 = "2"
    case picture3 = "3"
    case picture4 = "4"
    case picture5 = "5"
    case picture6 = "6"
    
    var index: Index {
        Int(rawValue) ?? 0 - 1
    }
    
    init?(with index: Index) {
        self.init(rawValue:String(index + 1))
    }
    
    var uiImage: UIImage {
        UIImage(named: rawValue) ?? UIImage()
    }
}
