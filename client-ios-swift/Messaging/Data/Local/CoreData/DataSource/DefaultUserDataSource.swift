/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import CoreData

final class DefaultUserDataSource: UserDataSource {
    private let coreDataController: CoreDataController
    private let fetchedResultsController: NSFetchedResultsController<UserObject>
    private let resultsControllerDelegate: FetchedResultsControllerDelegate<UserObject, User>
    var me: User? { coreDataController.me }
        
    init(context: NSManagedObjectContext, controller: CoreDataController) {
        let request = UserObject.defaultFetchRequest
        let displayNameSort = NSSortDescriptor(keyPath: \UserObject.displayName, ascending: true)
        request.sortDescriptors = [displayNameSort]
        
        fetchedResultsController = NSFetchedResultsController<UserObject>(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        coreDataController = controller
        resultsControllerDelegate = FetchedResultsControllerDelegate<UserObject, User>()
        fetchedResultsController.delegate = resultsControllerDelegate
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize \(String(describing: Self.self)): \(error)")
        }
    }
    
    func observeUsers(includingMe: Bool, observer: DataSourceObserver<User>) {
        resultsControllerDelegate.addObserver(observer, with: includingMe)
    }
    
    func removeObserver(_ observer: DataSourceObserver<User>) {
        resultsControllerDelegate.removeObserver(observer)
    }
    
    var allUsers: [User] {
        fetchedResultsController.sections?.first?.objects?.compactMap
            { ($0 as? UserObject)?.converted } ?? []
    }
    
    func getPossibleToAddUsers(for conversation: Conversation) -> [User] {
        let participants = conversation.participants.map { $0.user.id }
        let all = allUsers.map { $0.id }
        let diff = Array(Set(all).subtracting(participants))
        return diff.compactMap { getUser(with: NSNumber(value: $0)) }
    }
    
    func getUser(at indexPath: IndexPath, includingMe: Bool) -> User {
        if includingMe {
            return fetchedResultsController.object(at: indexPath).converted
        } else {
            return (fetchedResultsController.sections!.first!.objects as! [UserObject])
                .filter { !$0.me }[indexPath.row]
                .converted
        }
    }
    
    func getNumberOfUsers(includingMe: Bool) -> Int {
        if let numberOfUsers = fetchedResultsController.sections?.first?.numberOfObjects {
            return numberOfUsers - (includingMe ? 0 : 1)
        } else {
            return 0
        }
    }
    
    func getUser(with id: NSNumber) -> User? {
        coreDataController.getObject(of: UserObject.self, by: Int64(truncating: id))
    }
}
