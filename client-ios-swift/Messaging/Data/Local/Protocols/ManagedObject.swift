/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import CoreData

protocol Identifiable where ID: Equatable {
    associatedtype ID
    var id: ID { get }
}

extension Equatable where Self: Identifiable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}

protocol IDFetchable: NSManagedObject, Identifiable {
    static func makeFetchRequest(for key: ID) -> NSFetchRequest<Self>
}

protocol ManagedObject: Convertable, IDFetchable { }

protocol Predicatable {
    associatedtype Predicate
    func satisfiesPredicate(_ predicate: Predicate) -> Bool
}

extension ManagedObject {
    static var entityName: String { String(describing: Self.self) }
    static var defaultFetchRequest: NSFetchRequest<Self> { NSFetchRequest<Self>(entityName: entityName) }
    
    static func insert(into context: NSManagedObjectContext) -> Self {
        NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as! Self
    }
}
