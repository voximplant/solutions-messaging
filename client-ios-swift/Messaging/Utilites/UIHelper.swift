/*
 *  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
 */

import UIKit

final class UIHelper {    
    // MARK: Show errors methods
    static func ShowError(error: String, action: UIAlertAction? = nil, controller: UIViewController? = nil) {
        DispatchQueue.main.async {
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController  {
                
                let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                
                if let alertAction = action {
                    alert.addAction(alertAction)
                }
                
                if let specifiedController = controller {
                    specifiedController.present(alert, animated: true, completion: nil)
                } else {
                    let controllerToUse = rootViewController.toppestViewController
                    controllerToUse.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: - Loading HUD Methods
    private static let loadingWindow = LoadingWindow()
    
    static func showLoading(with title: String) { loadingWindow.set(state: .active(text: title)) }
    
    static func hideLoading() { loadingWindow.set(state: .inactive) }
}
