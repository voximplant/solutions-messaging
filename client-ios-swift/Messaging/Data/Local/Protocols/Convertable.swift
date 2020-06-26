/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

protocol Convertable {
    associatedtype ResultType
    associatedtype UpdateType
    
    var converted: ResultType { get }
    func update(from value: UpdateType)
}
