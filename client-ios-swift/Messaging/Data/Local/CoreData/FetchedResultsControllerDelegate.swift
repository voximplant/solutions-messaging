/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import CoreData

final class FetchedResultsControllerDelegate<Object, Content>:
    NSObject,
    NSFetchedResultsControllerDelegate
    where
    Object: Predicatable,
    Object: ManagedObject,
    Object.ResultType == Content
{
    private var observers: [(observer: DataSourceObserver<Content>, predicate: Object.Predicate?)] = []
    
    func addObserver(_ observer: DataSourceObserver<Content>, with predicate: Object.Predicate? = nil) {
        observers.append((observer, predicate))
    }
    
    func removeObserver(_ observer: DataSourceObserver<Content>) {
        observers.removeAll { $0.observer.id == observer.id }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        observers.forEach { $0.observer.contentWillChange?() }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        observers.forEach { $0.observer.contentDidChange?() }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?
    ) {
        switch type {
        case .insert:
            if let object = anObject as? Object,
                let indexPath = newIndexPath {
                notifyObservers(about: .insert(content: object.converted, at: indexPath), object: object)
            } else {
                Log.w("Received didChange anObject (insert) with incorrect object type \(anObject.self) or no indexPath \(String(describing: newIndexPath))")
            }
        case .delete:
            if let object = anObject as? Object,
                let indexPath = indexPath {
                notifyObservers(about:.delete(from: indexPath), object: object)
            } else {
                Log.w("Received didChange anObject (delete) with incorrect object type \(anObject.self) or no indexPath \(String(describing: newIndexPath))")
            }
        case .move:
            if let newIndexPath = newIndexPath,
                let indexPath = indexPath {
                notifyObservers(about: .move(from: indexPath, to: newIndexPath))
            } else {
                Log.w("Received didChange anObject (move) with nil newIndexPath \(String(describing: newIndexPath)) or indexPath \(String(describing: indexPath)) ")
            }
        case .update:
            if let object = anObject as? Object,
                let indexPath = indexPath {
                notifyObservers(about: .update(content: object.converted, at: indexPath), object: object)
            } else {
                Log.w("Received didChange anObject (update) with incorrect object type \(anObject.self) or empty indexPath \(String(describing: indexPath))")
            }
        @unknown default:
            Log.w("Received didChange anObject with unknown change type \(type)")
        }
    }
    
    private func notifyObservers(about change: DataSourceContentChange<Content>, object: Object? = nil) {
        self.observers.forEach { (observer, predicate) in
            if let predicate = predicate, let object = object {
                if object.satisfiesPredicate(predicate) {
                    observer.didReceiveChange(change)
                }
            } else {
                observer.didReceiveChange(change)
            }
        }
    }
}
