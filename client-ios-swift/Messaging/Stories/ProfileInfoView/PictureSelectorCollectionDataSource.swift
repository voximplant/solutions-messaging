/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

fileprivate let selectorCellID = "PictureSelectorViewCollectionViewCell"
fileprivate let selectorNibName = "PictureSelectorViewCollectionViewCell"

class PictureSelectorViewCollectionView: CollectionView {
    override var cellID: String { return selectorCellID }
    override var nibName: String { return selectorNibName }
}

extension CollectionViewDataSource where Model == PictureSelectorViewCellModel {
    static func make(for cellModels: [PictureSelectorViewCellModel], reuseIdentifier: String = selectorCellID) -> CollectionViewDataSource {
        return CollectionViewDataSource (models: cellModels, reuseIdentifier: reuseIdentifier) { (model, cell) in
            (cell as! PictureSelectorViewCollectionViewCell).model = model
        }
    }
}
