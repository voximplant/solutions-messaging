/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit
import SelectableStackView

protocol PictureSelectorViewDelegate: AnyObject {
    func didPressCancelButton()
    func didPressSaveButton(with imageName: String)
}

final class PictureSelectorView: UIView, NibLoadable, SelectableStackViewDelegate {
    weak var delegate: PictureSelectorViewDelegate?
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var saveButton: UIButton!
    @IBOutlet private weak var topStackView: SelectableStackView!
    @IBOutlet private weak var bottomStackView: SelectableStackView!
    private var selectedIndex: Index? {
        didSet {
            if let oldIndex = oldValue {
                if oldIndex < 3 {
                    topStackView.select(false, at: oldIndex)
                } else {
                    bottomStackView.select(false, at: oldIndex - 3)
                }
            }
            if let selectedIndex = selectedIndex {
                if selectedIndex < 3 {
                    topStackView.select(true, at: selectedIndex)
                } else {
                    bottomStackView.select(true, at: selectedIndex - 3)
                }
            }
            saveButton.isEnabled = selectedIndex != nil
        }
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
        topStackView.addArrangedSubview(ProfilePictureImageViewButton(picture: .picture1))
        topStackView.addArrangedSubview(ProfilePictureImageViewButton(picture: .picture2))
        topStackView.addArrangedSubview(ProfilePictureImageViewButton(picture: .picture3))
        topStackView.delegate = self
        
        bottomStackView.addArrangedSubview(ProfilePictureImageViewButton(picture: .picture4))
        bottomStackView.addArrangedSubview(ProfilePictureImageViewButton(picture: .picture5))
        bottomStackView.addArrangedSubview(ProfilePictureImageViewButton(picture: .picture6))
        bottomStackView.delegate = self
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        delegate?.didPressCancelButton()
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        if let selectedIndex = selectedIndex, let picture = Picture(with: selectedIndex) {
            delegate?.didPressSaveButton(with: picture.rawValue)
        }
    }
    
    func showImagePicker(with selectedImageName: String? = nil) {
        if let pictureName = selectedImageName,
            let picture = Picture(rawValue: pictureName) {
            selectWithPicture(picture)
        }
        showImagePicker(true)
    }
    
    func hideImagePicker() {
        selectedIndex = nil
        showImagePicker(false)
    }
    
    // MARK: - SelectableStackViewDelegate
    func didSelect(_ select: Bool, at index: Index, on selectableStackView: SelectableStackView) {
        if selectableStackView == topStackView {
            selectedIndex = select ? index : nil
        } else {
            selectedIndex = select ? index + 3 : nil
        }
    }
    
    // MARK: - Private
    private func selectWithPicture(_ picture: Picture) {
        selectedIndex = picture.index
    }
    
    private func showImagePicker(_ show: Bool) {
        UIView.animate(
            withDuration: 0.1,
            delay: 0,
            options: .allowUserInteraction,
            animations: { self.alpha = show ? 1 : 0 }
        )
    }
}
