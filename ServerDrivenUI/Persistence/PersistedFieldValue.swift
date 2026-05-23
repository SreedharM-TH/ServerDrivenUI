import CoreData

@objc(PersistedFieldValue)
final class PersistedFieldValue: NSManagedObject {
    @NSManaged var fieldId: String
    @NSManaged var data: Data
    @NSManaged var updatedAt: Date
}

extension PersistedFieldValue {
    static let entityName = "PersistedFieldValue"

    static func makeEntityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = entityName
        entity.managedObjectClassName = NSStringFromClass(PersistedFieldValue.self)

        let idAttr = NSAttributeDescription()
        idAttr.name = "fieldId"
        idAttr.attributeType = .stringAttributeType
        idAttr.isOptional = false

        let dataAttr = NSAttributeDescription()
        dataAttr.name = "data"
        dataAttr.attributeType = .binaryDataAttributeType
        dataAttr.isOptional = false

        let updatedAttr = NSAttributeDescription()
        updatedAttr.name = "updatedAt"
        updatedAttr.attributeType = .dateAttributeType
        updatedAttr.isOptional = false

        entity.properties = [idAttr, dataAttr, updatedAttr]
        return entity
    }
}
