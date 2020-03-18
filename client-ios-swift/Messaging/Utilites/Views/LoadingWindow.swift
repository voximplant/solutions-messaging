/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

enum LoadingWindowState: Equatable {
    case active (text: String)
    case inactive
}

final class LoadingWindow {
    private var topWindow: UIWindow? { UIApplication.shared.keyWindow }
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.2)
        return view
    }()
    private var loadingView: LoadingView?
    
    private var state: LoadingViewState = .inactive
    
    func set(state: LoadingViewState) {
        if self.state == state { return }
        if state == .inactive {
            overlayView.removeFromSuperview()
            loadingView?.set(state: .inactive)
            loadingView = nil
        } else if case .active(let text) = state {
            guard let topWindow = topWindow else { return }
            if let loadingView = loadingView {
                loadingView.set(state: .active(text: text))
                return
            }
            overlayView.frame = topWindow.bounds
            topWindow.addSubview(overlayView)
            
            loadingView = LoadingView()
            loadingView?.center = overlayView.center
            loadingView?.set(state: .active(text: text))
            overlayView.addSubview(loadingView!)
        }
        self.state = state
    }
}
