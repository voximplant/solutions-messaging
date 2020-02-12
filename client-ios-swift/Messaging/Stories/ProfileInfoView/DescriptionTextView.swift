/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class DescriptionTextView: UITextView, UITextViewDelegate {
    var placeholderText: String?
    var descriptionText: String? {
        get {
            if text == placeholderText || text == "" { return nil }
            else { return text }
        }
        set {
            if newValue == "" { text = placeholderText }
            else { text = newValue }
        }
    }
    
    private var isPlaceholderOn: Bool = false {
        didSet {
            textColor = isPlaceholderOn ? VoxColor.placeholderColor : VoxColor.textColor
        }
    }
    
    override var text: String? {
        didSet {
            if text == placeholderText { isPlaceholderOn = true }
            else { isPlaceholderOn = false }
        }
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame , textContainer: textContainer)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() { self.delegate = self }
    
    // MARK: - UITextViewDelegate
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            text = placeholderText
            isPlaceholderOn = true
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if isPlaceholderOn {
            textView.text = nil
            isPlaceholderOn = false
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        return updatedText.count <= 67
    }
}

fileprivate extension VoxColor {
    static var placeholderColor: UIColor {
        if #available(iOS 13.0, *) { return UIColor.placeholderText }
        else { return UIColor.lightGray }
    }
    
    static var textColor: UIColor {
        if #available(iOS 13.0, *) { return UIColor.label }
        else { return UIColor.black }
    }
}
