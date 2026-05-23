import CoreData

/// Core Data-backed implementation of `FormStatePersistence`.
/// Stores each field value as a single `PersistedFieldValue` row, with the
/// `FieldValue` enum encoded to JSON Data via the Codable conformance.
/// Upsert semantics: `save(_:)` replaces existing rows by `fieldId`.
final class CoreDataFormStatePersistence: FormStatePersistence {
    private let stack: CoreDataStack
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    func load() async throws -> [String: FieldValue] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String: FieldValue], Error>) in
            let context = stack.viewContext
            context.perform { [decoder] in
                do {
                    let request = NSFetchRequest<PersistedFieldValue>(entityName: PersistedFieldValue.entityName)
                    let rows = try context.fetch(request)
                    var result: [String: FieldValue] = [:]
                    for row in rows {
                        if let value = try? decoder.decode(FieldValue.self, from: row.data) {
                            result[row.fieldId] = value
                        }
                    }
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func clear() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = stack.viewContext
            context.perform {
                do {
                    let request = NSFetchRequest<PersistedFieldValue>(entityName: PersistedFieldValue.entityName)
                    let rows = try context.fetch(request)
                    for row in rows { context.delete(row) }
                    if context.hasChanges { try context.save() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func save(_ values: [String: FieldValue]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let context = stack.viewContext
            context.perform { [encoder] in
                do {
                    let request = NSFetchRequest<PersistedFieldValue>(entityName: PersistedFieldValue.entityName)
                    let existing = try context.fetch(request)
                    let byId = Dictionary(uniqueKeysWithValues: existing.map { ($0.fieldId, $0) })

                    let now = Date()
                    var seenIds = Set<String>()

                    for (fieldId, value) in values {
                        let encoded = try encoder.encode(value)
                        let row = byId[fieldId] ?? PersistedFieldValue(context: context)
                        row.fieldId = fieldId
                        row.data = encoded
                        row.updatedAt = now
                        seenIds.insert(fieldId)
                    }

                    // Garbage-collect rows whose field id is no longer in the current form.
                    for (id, row) in byId where !seenIds.contains(id) {
                        context.delete(row)
                    }

                    if context.hasChanges {
                        try context.save()
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
