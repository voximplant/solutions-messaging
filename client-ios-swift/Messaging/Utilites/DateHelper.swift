/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

fileprivate let HHmmDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm"
    return dateFormatter
}()

func buildStringTime(from timeInterval: TimeInterval) -> String {
    let time = Date(timeIntervalSince1970: timeInterval)
    return HHmmDateFormatter.string(from: time)
}
