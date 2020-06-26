/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

enum CoreDataError: Error {
    case dataProcessingError (String)
    case dataNotFound (Any.Type)
}

extension CoreDataError {
    var localizedDescription: String {
        switch self {
        case .dataProcessingError(let text):
            return "Data processing error: \(text)"
        case .dataNotFound (let type):
            return "Data of \(type) was not found in data base"
        }
    }
}
