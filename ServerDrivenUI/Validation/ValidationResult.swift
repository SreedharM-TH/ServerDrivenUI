import Foundation

enum ValidationResult: Equatable {
    case valid
    case invalid(message: String)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    var message: String? {
        if case .invalid(let m) = self { return m }
        return nil
    }
}
