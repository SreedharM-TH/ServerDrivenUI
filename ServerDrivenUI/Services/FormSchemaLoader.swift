import Foundation

protocol FormSchemaLoader {
    func load() async throws -> FormSchema
}
