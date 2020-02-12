/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

struct ChannelProfileModel {
    var title: String
    var pictureName: String?
    var description: String?
}

struct GroupChatProfileModel {
    var title: String
    var pictureName: String?
    var description: String?
    var isUber: Bool
    var isPublic: Bool
}

struct UserProfileModel {
    var name: String
    var pictureName: String?
    var status: String?
}

enum ProfileType {
    case user (model: UserProfileModel)
    case groupChat (model: GroupChatProfileModel)
    case channel (model: ChannelProfileModel)
}

@IBDesignable
final class ProfileInfoView: UIView, NibLoadable, PictureSelectorViewDelegate {
    @IBOutlet weak var profileImageView: ProfilePictureView!
    @IBOutlet private weak var changePictureButton: RoundButton!
    
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var bottomLineView: UIView!

    @IBOutlet weak var conversationSettingsView: UIView!
    @IBOutlet weak var conversationSettingsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var uberContainer: UIView!
    @IBOutlet private weak var uberSwitch: UISwitch!
    @IBOutlet private weak var publicSwitch: UISwitch!

    @IBOutlet private weak var descriptionTextView: DescriptionTextView!
    @IBInspectable var descriptionPlaceholder: String? { didSet { descriptionTextView.placeholderText = descriptionPlaceholder } }
    var descriptionText: String? {
        get { return descriptionTextView.descriptionText }
        set { descriptionTextView.descriptionText = newValue }
    }
    
    private var pictureSelector: PictureSelectorView!
    
    var type: ProfileType! {
        didSet {
            switch type {
            case .user(let model):
                showAdditionalSettings(false)
                nameTextField.isUserInteractionEnabled = false
                descriptionPlaceholder = "Bio"
                namePlaceholder = "Full Name"
                profileImageView.isForUser = true
                title = model.name
                descriptionText = model.status ?? ""
                profileImageView.profileName = model.name
                profileImageView.name = model.pictureName
            case .groupChat(let model):
                showAdditionalSettings(true)
                nameTextField.isUserInteractionEnabled = false
                descriptionPlaceholder = "Description"
                namePlaceholder = "Conversation Name"
                title = model.title
                descriptionText = model.description ?? ""
                profileImageView.isForUser = false
                profileImageView.profileName = model.title
                profileImageView.name = model.pictureName
                isUber = model.isUber
                isPublic = model.isPublic
            case .channel(let model):
                showAdditionalSettings(false)
                nameTextField.isUserInteractionEnabled = false
                descriptionPlaceholder = "Description"
                namePlaceholder = "Channel Name"
                profileImageView.isForUser = false
                title = model.title
                descriptionText = model.description ?? ""
                profileImageView.profileName = model.title
                profileImageView.name = model.pictureName
            default:
                fatalError()
            }
            isEditable = false
        }
    }
    
    var title: String? {
        get { return nameTextField.text }
        set { nameTextField.text = newValue }
    }
    
    var pictureName: String? {
        get { return profileImageView.name }
        set { profileImageView.name = newValue }
    }
    
    var isUber: Bool? {
        get { return uberSwitch.isOn }
        set {
            guard let isOn = newValue else { return }
            if !isEditable { return }
            if uberSwitch == nil { return }
            uberSwitch.setOn(isOn, animated: true)
        }
    }
    
    var isPublic: Bool? {
        get { return publicSwitch.isOn }
        set {
            guard let isOn = newValue else { return }
            if !isEditable { return }
            publicSwitch.setOn(isOn, animated: true)
        }
    }
    
    private var namePlaceholder: String? { didSet { nameTextField.placeholder = namePlaceholder } }
    
    var isEditable: Bool = false {
        didSet {
            changePictureButton.isHidden = !isEditable
            bottomLineView.isHidden = !isEditable
            nameTextField.isUserInteractionEnabled = isEditable
            descriptionTextView.isUserInteractionEnabled = isEditable
            switch type {
            case .user(_):
                bottomLineView.isHidden = true
                showAdditionalSettings(false)
                nameTextField.isUserInteractionEnabled = false
            case .channel(_):
                showAdditionalSettings(false)
            case .groupChat(_):
                showAdditionalSettings(isEditable)
            case .none:
                fatalError()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
    }
    
    override func awakeFromNib() { setupPictureSelector() }
    
    // MARK: - User Actions
    @IBAction func changePictureButtonPressed(_ sender: RoundButton) {
        pictureSelector.showImagePicker(with: profileImageView.name)
    }
    
    func didPressSaveButton(with imageName: String) {
        pictureSelector.hideImagePicker()
        profileImageView.name = imageName
    }

    func didPressCancelButton() {
        pictureSelector.hideImagePicker()
    }
    
    // MARK: - Private Methods
    private func showAdditionalSettings(_ show: Bool) {
        conversationSettingsViewHeightConstraint.constant = show ? 51 : 15
        conversationSettingsView.isHidden = !show
        guard let isPublic = isPublic else { return }
        publicSwitch.isOn = isPublic
    }
    
    private func setupPictureSelector() {
        pictureSelector = PictureSelectorView(frame: UIScreen.main.bounds)
        pictureSelector.alpha = 0
        UIApplication.shared.windows.last?.addSubview(pictureSelector)
        pictureSelector.delegate = self
    }
    
}

fileprivate extension String {
    var appendingLimitInfo: String {
        get { return "\(self) (67 symbols limit)"}
    }
}
