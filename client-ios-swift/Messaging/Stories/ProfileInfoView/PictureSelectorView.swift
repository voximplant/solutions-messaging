/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol PictureSelectorViewDelegate: AnyObject {
    func didPressCancelButton()
    func didPressSaveButton(with imageName: String)
}

class PictureSelectorView: UIView, NibLoadable, UICollectionViewDelegate {
    weak var delegate: PictureSelectorViewDelegate?
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var collectionView: PictureSelectorViewCollectionView!
    @IBOutlet weak var saveButton: UIButton!
    
    private let dataSource = CollectionViewDataSource.make(for: [PictureSelectorViewCellModel(imageName: "1", isSelected: false),
                                                                 PictureSelectorViewCellModel(imageName: "2", isSelected: false),
                                                                 PictureSelectorViewCellModel(imageName: "3", isSelected: false),
                                                                 PictureSelectorViewCellModel(imageName: "4", isSelected: false),
                                                                 PictureSelectorViewCellModel(imageName: "5", isSelected: false),
                                                                 PictureSelectorViewCellModel(imageName: "6", isSelected: false)])
    
    private var modelArray: [PictureSelectorViewCellModel] {
        get { return dataSource.models }
        set { dataSource.models = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
        sharedInit()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
        sharedInit()
    }
    
    private func sharedInit() {
        containerView.layer.cornerRadius = 12
        collectionView.delegate = self
        collectionView.dataSource = dataSource
        if modelArray.contains(where: { $0.isSelected }) {
            saveButton.isEnabled = true
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        delegate?.didPressCancelButton()
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        guard let selectedImageName = (modelArray.first { $0.isSelected }?.imageName) else { return }
        delegate?.didPressSaveButton(with: selectedImageName)
    }
    
    func showImagePicker(with selectedImageName: String? = nil) {
        if let imageName = selectedImageName {
            modelArray.forEach {
                if $0.imageName == imageName {
                    $0.isSelected = true
                }
            }
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .allowUserInteraction, animations: {
            self.alpha = 1
        })
    }
    
    func hideImagePicker() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .allowUserInteraction, animations: { self.alpha = 0 })
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        modelArray.forEach { $0.isSelected = false }
        modelArray[indexPath.row].isSelected = true
        saveButton.isEnabled = true
        collectionView.reloadData()
    }
}
