import Foundation

struct RequiredValidator: Validator {
    func validate(value: FieldValue, field: FormField) -> ValidationResult {
        guard field.required else { return .valid }
        if value.isEmpty {
            let message = field.errorMessage ?? "\(field.label) is required."
            return .invalid(message: message)
        }
        return .valid
    }
}
