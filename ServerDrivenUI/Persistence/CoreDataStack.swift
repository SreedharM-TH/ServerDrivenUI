import CoreData

/// Programmatic Core Data stack — no .xcdatamodeld file required, which keeps
/// the model in source and avoids friction with Xcode's File System Synchronization.
/// Single entity (`PersistedFieldValue`) is described in code via
/// `PersistedFieldValue.makeEntityDescription()`.
final class CoreDataStack {
    let container: NSPersistentContainer

    init(inMemory: Bool = false, storeName: String = "FormState") {
        let model = NSManagedObjectModel()
        model.entities = [PersistedFieldValue.makeEntityDescription()]

        container = NSPersistentContainer(name: storeName, managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("Failed to load persistent store: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    var viewContext: NSManagedObjectContext { container.viewContext }
}
