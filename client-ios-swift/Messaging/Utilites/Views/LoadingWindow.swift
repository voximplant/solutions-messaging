/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

final class LoadingWindow {
    private var topWindow: UIWindow? { return UIApplication.shared.windows.last }
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.2)
        view.alpha = 0
        return view
    }()
    private var loadingView: LoadingView?
    
    func showLoading(with text: String) {
        guard let topWindow = topWindow else { return }
        if let loadingView = loadingView { loadingView.updateLoading(with: text) }
        else {
        overlayView.frame = topWindow.bounds
        topWindow.addSubview(overlayView)
        
        loadingView = LoadingView()
        loadingView?.center = overlayView.center
        loadingView?.showLoading(with: text)
        overlayView.addSubview(loadingView!)
        
        UIView.animate(withDuration: 0.5) { self.overlayView.alpha = 1 }
        }
    }
    
    func hideLoading() {
        UIView.animate(withDuration: 0.5, animations: { self.overlayView.alpha = 0}) { _ in
            self.overlayView.removeFromSuperview()
            self.loadingView = nil
        }
    }
}
