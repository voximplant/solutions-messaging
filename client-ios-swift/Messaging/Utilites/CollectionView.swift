/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

class CollectionView: UICollectionView {
    var cellID: String { return "" }
    
    var nibName: String { return "" }
    
    var nib: UINib { return UINib(nibName: nibName, bundle: nil) }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        sharedInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }
    
    private func sharedInit() { register(nib, forCellWithReuseIdentifier: cellID) }
}
