import Foundation

struct RegexValidator: Validator {
    func validate(value: FieldValue, field: FormField) -> ValidationResult {
        guard case .text(let spec) = field.kind, let pattern = spec.regex, !pattern.isEmpty else {
            return .valid
        }
        guard case .text(let text) = value else { return .valid }
        if text.isEmpty { return .valid }

        guard let regex = try? NSRegularExpression(pattern: pattern) else { return .valid }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matched = regex.firstMatch(in: text, options: [], range: range) != nil

        if !matched {
            let message = field.errorMessage ?? "\(field.label) format is invalid."
            return .invalid(message: message)
        }
        return .valid
    }
}
