/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import CoreData

final class DefaultConversationDataSource: ConversationDataSource {
    private let coreDataController: CoreDataController
    private let fetchedResultsController: NSFetchedResultsController<ConversationObject>
    private let resultsControllerDelegate: FetchedResultsControllerDelegate<ConversationObject, Conversation>
            
    var numberOfConversations: Int {
        fetchedResultsController.sections?.first?.numberOfObjects ?? 0
    }

    init(context: NSManagedObjectContext, controller: CoreDataController) {
        let request = ConversationObject.defaultFetchRequest
        let updateTimeSort = NSSortDescriptor(keyPath: \ConversationObject.lastUpdatedTime,
                                              ascending: false)
        request.sortDescriptors = [updateTimeSort]
        
        fetchedResultsController = NSFetchedResultsController<ConversationObject>(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        coreDataController = controller
        resultsControllerDelegate = FetchedResultsControllerDelegate<ConversationObject, Conversation>()
        fetchedResultsController.delegate = resultsControllerDelegate
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize \(String(describing: Self.self)): \(error)")
        }
    }
    
    func observeConversations(_ observer: DataSourceObserver<Conversation>) {
        resultsControllerDelegate.addObserver(observer)
    }
    
    func observeConversation(with uuid: String, _ observer: DataSourceObserver<Conversation>) {
        resultsControllerDelegate.addObserver(observer, with: uuid)
    }
    
    func removeObserver(_ observer: DataSourceObserver<Conversation>) {
        resultsControllerDelegate.removeObserver(observer)
    }
    
    func getConversation(at indexPath: IndexPath) -> Conversation {
        fetchedResultsController.object(at: indexPath).converted
    }

    func getConversation(with uuid: String) -> Conversation? {
        coreDataController.getObject(of: ConversationObject.self, by: uuid)
    }
}
