/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

protocol Cleanable {
    func clean(completion: @escaping (Error?) -> Void) 
}
