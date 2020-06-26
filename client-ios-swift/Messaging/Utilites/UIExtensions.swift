/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit

extension UIStoryboard {
    func instantiateViewController<Type: UIViewController>(of type: Type.Type) -> Type {
        instantiateViewController(withIdentifier: String(describing: type)) as! Type
    }
}

extension UIViewController { // use this method to hide keyboard on tap on specific VC
    func hideKeyboardWhenTappedAround(on view: UIView? = nil) {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        (view ?? self.view).addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension UIViewController {
    var topPresentedController: UIViewController {
        if let presentedViewController = self.presentedViewController {
            return presentedViewController.topPresentedController
        } else {
            return self
        }
    }
    
    var toppestViewController: UIViewController {
        if let navigationvc = self as? UINavigationController {
            if let navigationsTopViewController = navigationvc.topViewController {
                return navigationsTopViewController.topPresentedController
            } else {
                return navigationvc // no children
            }
        } else if let tabbarvc = self as? UITabBarController {
            if let selectedViewController = tabbarvc.selectedViewController {
                return selectedViewController.topPresentedController
            } else {
                return self // no children
            }
        } else if let firstChild = self.children.first {
            // other container's view controller
            return firstChild.topPresentedController
        } else {
            return self.topPresentedController
        }
    }
}
