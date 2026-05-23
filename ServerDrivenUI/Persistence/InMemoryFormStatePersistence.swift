import Foundation

/// In-memory implementation for unit tests of `FormViewModel` that do not
/// require exercising the Core Data stack. Round-trip Core Data behavior is
/// covered separately in `PersistenceTests`.
actor InMemoryFormStatePersistence: FormStatePersistence {
    private var storage: [String: FieldValue]

    init(seed: [String: FieldValue] = [:]) {
        self.storage = seed
    }

    func load() async throws -> [String: FieldValue] { storage }

    func save(_ values: [String: FieldValue]) async throws {
        storage = values
    }

    func clear() async throws {
        storage = [:]
    }
}
