import Foundation

struct MaxLengthValidator: Validator {
    func validate(value: FieldValue, field: FormField) -> ValidationResult {
        guard case .text(let spec) = field.kind, let max = spec.maxLength else { return .valid }
        guard case .text(let text) = value else { return .valid }
        if text.count > max {
            let message = field.errorMessage ?? "\(field.label) must be \(max) characters or fewer."
            return .invalid(message: message)
        }
        return .valid
    }
}
