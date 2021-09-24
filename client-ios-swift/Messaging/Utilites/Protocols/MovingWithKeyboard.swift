/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol MovingWithKeyboard: AnyObject {
    var adjusted: Bool { get set }
    var defaultValue: CGFloat { get set }
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
            guard let keyboardBeginFrame = notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect,
                  let keyboardEndFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                let self = self
                else { return }
            
            if !self.adjusted {
                if #available(iOS 11.0, *) {
                    let keyboardHeight = keyboardBeginFrame.origin.y - keyboardEndFrame.origin.y
                    self.defaultValue = keyboardHeight - self.view.safeAreaInsets.bottom
                    self.additionalSafeAreaInsets.bottom += keyboardHeight - self.view.safeAreaInsets.bottom
                } else {
                    self.defaultValue = self.view.frame.origin.y
                    self.view.frame.origin.y -= (keyboardEndFrame.height) * self.moveMultiplier
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
            
            if self.adjusted {
                if #available(iOS 11.0, *) {
                    self.additionalSafeAreaInsets.bottom -= self.defaultValue
                } else {
                    self.view.frame.origin.y = self.defaultValue
                }
                
                self.adjusted = false
            }
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
