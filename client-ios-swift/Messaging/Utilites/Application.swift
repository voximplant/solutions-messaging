//
//  Application.swift
//  Messaging
//
//  Created by Vladimir Korolev on 12.11.2019.
//  Copyright © 2019 Voximplant. All rights reserved.
//

import UIKit

extension UIApplication {
    class var errorDomain: String {
        return Bundle.main.bundleIdentifier!
    }
}

extension UIApplication {
    class var userDefaultsDomain: String {
        return Bundle.main.bundleIdentifier!
    }
}
