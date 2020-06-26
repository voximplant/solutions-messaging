/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol MovingWithKeyboard: AnyObject {
    var adjusted: Bool { get set }
    var defaultPositionY: CGFloat { get set }
    var moveMultiplier: CGFloat { get }
    var keyboardWillChangeFrameObserver: NSObjectProtocol? { get set }
    var keyboardWillHideObserver: NSObjectProtocol? { get set }
}

extension MovingWithKeyboard where Self: UIViewController {
    var moveMultiplier: CGFloat { 0.5 }
    
    func subscribeOnKeyboardEvents() {
        keyboardWillChangeFrameObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] notification in
            guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
                let self = self
                else { return }
            let keyboardScreenEndFrame = keyboardValue.cgRectValue
            if !self.adjusted {
                self.defaultPositionY = self.view.frame.origin.y
                if #available(iOS 11.0, *) {
                    self.view.frame.origin.y -= (keyboardScreenEndFrame.height - self.view.safeAreaInsets.bottom) * self.moveMultiplier
                } else {
                    self.view.frame.origin.y -= (keyboardScreenEndFrame.height) * self.moveMultiplier
                }
                self.adjusted = true
            }
        }
        
        keyboardWillHideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] notification in
            guard let self = self else { return }
            self.view.frame.origin.y = self.defaultPositionY
            self.adjusted = false
        }
    }
    
    func unsubscribeFromKeyboardEvents() {
        if let changeFrameObserver = keyboardWillChangeFrameObserver {
            NotificationCenter.default.removeObserver(changeFrameObserver)
        }
        if let willHideObserver = keyboardWillHideObserver {
            NotificationCenter.default.removeObserver(willHideObserver)
        }
    }
}


extension MovingWithKeyboard where Self: UIView {
    func subscribeOnKeyboardEvents() {
        keyboardWillChangeFrameObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] notification in
            guard let self = self,
                let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                    as? NSValue else {
                        return
            }
            let keyboardScreenEndFrame = keyboardValue.cgRectValue
            if !self.adjusted {
                self.defaultPositionY = self.frame.origin.y
                if #available(iOS 11.0, *) {
                    self.frame.origin.y -=
                        (keyboardScreenEndFrame.height - self.safeAreaInsets.bottom) / 2
                } else {
                    self.frame.origin.y -= (keyboardScreenEndFrame.height) / 2
                }
                self.adjusted = true
            }
        }
        
        keyboardWillHideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] notification in
            guard let self = self else { return }
            self.frame.origin.y = self.defaultPositionY
            self.adjusted = false
        }
    }
    
    func unsubscribeFromKeyboardEvents() {
        if let changeFrameObserver = keyboardWillChangeFrameObserver {
            NotificationCenter.default.removeObserver(changeFrameObserver)
        }
        if let willHideObserver = keyboardWillHideObserver {
            NotificationCenter.default.removeObserver(willHideObserver)
        }
    }
}
