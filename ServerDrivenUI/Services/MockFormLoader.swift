import Foundation

struct MockFormLoader: FormSchemaLoader {
    enum Outcome {
        case success(FormSchema)
        case failure(Error)
    }

    let outcome: Outcome

    init(schema: FormSchema) { self.outcome = .success(schema) }
    init(error: Error) { self.outcome = .failure(error) }

    func load() async throws -> FormSchema {
        switch outcome {
        case .success(let schema): return schema
        case .failure(let error): throw error
        }
    }
}
