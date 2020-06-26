/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

extension TimeInterval {
    var timeString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: Date(timeIntervalSince1970: self))
    }
}

extension String {
    var withAccount: String {
        "\(self)@\(VoximplantConfig.appName).\(VoximplantConfig.accountName)"
    }
    
    var withVoximplantDomain: String {
        "\(self).voximplant.com"
    }
}

func forEach<Input>(
    data: [Input],
    method: @escaping (Input, @escaping (Error?) -> Void) -> Void,
    completion: @escaping (Error?) -> Void
) {
    let numberOfIterations = data.count
    var iterationsCompleted = 0
    var firstErrorReceived: Error?
    data.forEach { data in
        method(data) { error in
            if let error = error {
                firstErrorReceived = error
            }
            iterationsCompleted += 1
            if iterationsCompleted == numberOfIterations { completion(firstErrorReceived) }
        }
    }
}
