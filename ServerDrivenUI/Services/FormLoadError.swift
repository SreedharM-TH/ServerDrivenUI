import Foundation

enum FormLoadError: LocalizedError, Equatable {
    case fileMissing(name: String)
    case decodingFailed(description: String)
    case empty

    var errorDescription: String? {
        switch self {
        case .fileMissing(let name):
            return "Could not find \(name) in the app bundle."
        case .decodingFailed(let description):
            return "The form payload could not be parsed. \(description)"
        case .empty:
            return "The form payload is empty."
        }
    }
}
