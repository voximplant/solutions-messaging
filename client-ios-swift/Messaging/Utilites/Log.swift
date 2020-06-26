/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/
import Foundation

final class Log {
    static var loggingEnabled: Bool = true
    fileprivate static let prefix = "[Messaging Demo"
    
    static func e(file: String = #file, function: String = #function, _ message: String) {
        log("ERROR] \(Thread.current) \(file.withoutFileExtension.withoutFilePath).\(function): \(message)")
    }
    
    static func w(file: String = #file, function: String = #function, _ message: String) {
        log("WARNING] \(Thread.current) \(file.withoutFileExtension.withoutFilePath).\(function): \(message)")
    }
    
    static func i(file: String = #file, function: String = #function, _ message: String) {
        log("INFO] \(Thread.current) \(file.withoutFileExtension.withoutFilePath).\(function): \(message)")
    }
    
    static func log(_ message: String) {
        if loggingEnabled {
            print("\(prefix) \(message)")
        }
    }
}

fileprivate extension String {
    var withoutFileExtension: String {
        var components = self.components(separatedBy: ".")
        if components.count <= 1 { return self }
        components.removeLast()
        return components.joined()
    }
    
    var withoutFilePath: String {
        components(separatedBy: "/").last ?? self
    }
}
