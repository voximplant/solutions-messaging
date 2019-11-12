/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import Foundation

func log(_ message: String, _ file: String = #file, _ line: Int = #line, _ function: String = #function) {
    print("[\(file):\(line)] \(function) - \(message)")
}
