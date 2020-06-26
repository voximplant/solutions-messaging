/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

@IBDesignable
final class ProfileInfoView: UIView, NibLoadable, PictureSelectorViewDelegate {
    enum ProfileInfoViewState: Equatable {
        case initial (type: ProfileType)
        case normal
        case editing
    }
    
    enum ProfileType: Equatable {
        case user
        case groupChat
        case channel
    }
    
    struct ProfileInfoViewModel {
        var title: String
        var pictureName: String?
        var description: String?
        var isUber: Bool? = nil
        var isPublic: Bool? = nil
    }
    
    @IBOutlet weak var profileImageView: ProfilePictureView!
    @IBOutlet private weak var changePictureButton: RoundButton!
    
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var bottomLineView: UIView!

    @IBOutlet weak var conversationSettingsView: UIView!
    @IBOutlet weak var conversationSettingsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var uberContainer: UIView!
    @IBOutlet private weak var uberSwitch: UISwitch!
    @IBOutlet private weak var publicSwitch: UISwitch!
    
    private var pictureSelector: PictureSelectorView!

    @IBOutlet private weak var descriptionTextView: DescriptionTextView!
    @IBInspectable var descriptionPlaceholder: String? {
        didSet {
            descriptionTextView.placeholderText = descriptionPlaceholder
        }
    }
    var descriptionText: String? {
        get { descriptionTextView.descriptionText }
        set { descriptionTextView.descriptionText = newValue }
    }
    
    private var type: ProfileType?
    
    private(set) var state: ProfileInfoViewState? {
        didSet {
            switch state {
            case .initial(let type):
                self.type = type
                changePictureButton.isHidden = true
                bottomLineView.isHidden = true
                nameTextField.isUserInteractionEnabled = false
                descriptionTextView.isUserInteractionEnabled = false
                showAdditionalSettings(false)
                switch type {
                case .user:
                    descriptionPlaceholder = "Bio"
                    namePlaceholder = "Full Name"
                case .groupChat:
                    descriptionPlaceholder = "Description"
                    namePlaceholder = "Conversation Name"
                case .channel:
                    descriptionPlaceholder = "Description"
                    namePlaceholder = "Channel Name"
                }
            case .editing:
                changePictureButton.isHidden = false
                bottomLineView.isHidden = false
                nameTextField.isUserInteractionEnabled = true
                descriptionTextView.isUserInteractionEnabled = true
                switch self.type {
                case .user:
                    bottomLineView.isHidden = true
                    showAdditionalSettings(false)
                    nameTextField.isUserInteractionEnabled = false
                case .channel:
                    showAdditionalSettings(false)
                case .groupChat:
                    showAdditionalSettings(true)
                case .none:
                    break
                }
            case .normal:
                changePictureButton.isHidden = true
                bottomLineView.isHidden = true
                nameTextField.isUserInteractionEnabled = false
                descriptionTextView.isUserInteractionEnabled = false
                switch self.type {
                case .user:
                    bottomLineView.isHidden = true
                    showAdditionalSettings(false)
                    nameTextField.isUserInteractionEnabled = false
                case .channel:
                    showAdditionalSettings(false)
                case .groupChat:
                    showAdditionalSettings(false)
                case .none:
                    break
                }
            default:
                break
            }
        }
    }
    
    private var model: ProfileInfoViewModel? {
        didSet {
            title = model?.title
            descriptionText = model?.description ?? ""
            profileImageView.profileName = model?.title
            profileImageView.name = model?.pictureName
            isUber = model?.isUber
            isPublic = model?.isPublic
        }
    }
    
    private(set) var title: String? {
        get { nameTextField.text }
        set { nameTextField.text = newValue }
    }
    
    private(set) var pictureName: String? {
        get { profileImageView.name }
        set { profileImageView.name = newValue }
    }
    
    private(set) var isUber: Bool? {
        get {
            uberSwitch.isOn
        }
        set {
            guard let isOn = newValue, state == .editing, uberSwitch != nil else { return }
            uberSwitch.setOn(isOn, animated: true)
        }
    }
    
    private(set) var isPublic: Bool? {
        get {
            publicSwitch.isOn
        }
        set {
            guard let isOn = newValue, state == .editing, publicSwitch != nil else { return }
            publicSwitch.setOn(isOn, animated: true)
        }
    }
    
    private var namePlaceholder: String? {
        didSet {
            nameTextField.placeholder = namePlaceholder
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
    
    override func awakeFromNib() {
        pictureSelector = PictureSelectorView(frame: UIScreen.main.bounds)
        pictureSelector.alpha = 0
        UIApplication.shared.windows.last?.addSubview(pictureSelector)
        pictureSelector.delegate = self
    }
    
    func setState(_ state: ProfileInfoViewState) {
        self.state = state
    }
    
    func setModel(_ model: ProfileInfoViewModel) {
        self.model = model
    }
    
    // MARK: - User Actions
    @IBAction private func changePictureButtonPressed(_ sender: RoundButton) {
        nameTextField.endEditing(true)
        descriptionTextView.endEditing(true)
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
        conversationSettingsViewHeightConstraint.constant = show ? 51 : 0
        conversationSettingsView.isHidden = !show
        guard let isPublic = isPublic else { return }
        publicSwitch.isOn = isPublic
    }
}

fileprivate extension String {
    var appendingLimitInfo: String {
        "\(self) (67 symbols limit)"
    }
}
