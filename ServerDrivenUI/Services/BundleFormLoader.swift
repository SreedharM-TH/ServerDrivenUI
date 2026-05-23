import Foundation

struct BundleFormLoader: FormSchemaLoader {
    let resourceName: String
    let bundle: Bundle

    init(resourceName: String = "form_schema", bundle: Bundle = .main) {
        self.resourceName = resourceName
        self.bundle = bundle
    }

    func load() async throws -> FormSchema {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw FormLoadError.fileMissing(name: "\(resourceName).json")
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw FormLoadError.decodingFailed(description: error.localizedDescription)
        }

        guard !data.isEmpty else { throw FormLoadError.empty }

        do {
            return try JSONDecoder().decode(FormSchema.self, from: data)
        } catch {
            throw FormLoadError.decodingFailed(description: String(describing: error))
        }
    }
}
