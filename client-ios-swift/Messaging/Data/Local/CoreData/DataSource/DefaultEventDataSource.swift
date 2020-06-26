/*
*  Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
*/

import CoreData

final class DefaultEventDataSource:
    NSObject,
    NSFetchedResultsControllerDelegate,
    EventDataSource
{
    private var observer: DataSourceObserver<MessengerEvent>?
    private var observedConversationUUID: String?
    private let fetchedResultsController: NSFetchedResultsController<MessengerEventObject>
    private var context: NSManagedObjectContext {
        fetchedResultsController.managedObjectContext
    }
    private let cacheName = "cachedMessengerEvents"
    
    init(context: NSManagedObjectContext) {
        let request = NSFetchRequest<MessengerEventObject>(
            entityName: String(describing: MessengerEventObject.self)
        )
        // uuidSort is used for sections
        let uuidSort = NSSortDescriptor(keyPath: \MessengerEventObject.conversation.uuid, ascending: true)
        let sequenceSort = NSSortDescriptor(keyPath: \MessengerEventObject.sequence, ascending: false)
        request.sortDescriptors = [uuidSort, sequenceSort]
        fetchedResultsController = NSFetchedResultsController<MessengerEventObject>(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: "conversation.uuid",
            cacheName: "cachedMessengerEvents"
        )
        
        super.init()
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize \(String(describing: Self.self)): \(error)")
        }
    }
    
    func observeConversation(uuid: String, observer: DataSourceObserver<MessengerEvent>) {
        observedConversationUUID = uuid
        self.observer = observer
    }
    
    func removeObservers() {
        observedConversationUUID = nil
        observer = nil
    }
    
    func getNumberOfEvents(conversation: Conversation) -> Int {
        self[eventsWithUUID: conversation.uuid]?.count ?? 0
    }
    
    func getEvent(conversation: Conversation, at indexPath: IndexPath) -> MessengerEvent {
        guard let section = fetchedResultsController.sections?.firstIndex(
            where: { $0.name == conversation.uuid }) else {
                fatalError()
        }
        
        if let messageEvent = fetchedResultsController
            .object(at: IndexPath(row: indexPath.row, section: section)) as? MessageEventObject {
            return messageEvent.converted
        }
        if let conversationEvent = fetchedResultsController.object(
            at: IndexPath(row: indexPath.row, section: section)) as? ConversationEventObject {
            return conversationEvent.converted
        }
        
        fatalError()
    }
        
    func getLatestStoredEventSequence(conversationUUID uuid: String) -> Int64? {
        self[eventsWithUUID: uuid]?.first?.sequence
    }
    
    func cleanCache() {
        NSFetchedResultsController<MessengerEventObject>.deleteCache(withName: cacheName)
    }
    
    // MARK: - Private -
    private subscript (eventsWithUUID uuid: String) -> [MessengerEventObject]? {
        fetchedResultsController.sections?.first(where: { $0.name == uuid })?.objects as? [MessengerEventObject]
    }
    
    // MARK: - NSFetchedResultsControllerDelegate -
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        observer?.contentWillChange?()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        observer?.contentDidChange?()
    }
        
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?
    ) {
        switch type {
        case .insert:
            Log.i("Received didChange (insert)")
            if let object = anObject as? MessengerEventObject,
                let indexPath = newIndexPath,
                sectionObserved(section: indexPath.section) {
                if let messageEventObject = object as? MessageEventObject {
                    observer?.didReceiveChange(.insert(content: messageEventObject.converted, at: indexPath.withoutSection))
                } else if let conversationEventObject = object as? ConversationEventObject {
                    observer?.didReceiveChange(.insert(content: conversationEventObject.converted, at: indexPath.withoutSection))
                }
            }
            
        case .delete:
            Log.i("Received didChange (delete)")
            
        case .move:
            Log.i("Received didChange (move)")
            if let _ = anObject as? MessengerEventObject,
                let oldIndexPath = indexPath,
                let newIndexPath = newIndexPath,
                sectionObserved(section: oldIndexPath.section) {
                observer?.didReceiveChange(.move(from: oldIndexPath.withoutSection, to: newIndexPath.withoutSection))
            }
            
        case .update:
            Log.i("Received didChange (update)")
            if let object = anObject as? MessengerEventObject,
                let indexPath = indexPath,
                sectionObserved(section: indexPath.section) {
                if let messageEventObject = object as? MessageEventObject {
                    observer?.didReceiveChange(.update(content: messageEventObject.converted, at: indexPath.withoutSection))
                } else if let conversationEventObject = object as? ConversationEventObject {
                    observer?.didReceiveChange(.update(content: conversationEventObject.converted, at: indexPath.withoutSection))
                }
            }
            
        @unknown default:
            Log.w("Received didChange anObject with unknown change type \(type)")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    sectionIndexTitleForSectionName sectionName: String) -> String? {
        sectionName
    }
    
    private func sectionObserved(section: Int) -> Bool {
        if let controllerSections = fetchedResultsController.sections,
            controllerSections.indices.contains(section),
            let observedConversation = observedConversationUUID,
            controllerSections[section].name == observedConversation {
            return true
        } else {
            return false
        }
    }
}

fileprivate extension IndexPath {
    var withoutSection: IndexPath {
        IndexPath(row: row, section: 0)
    }
}
