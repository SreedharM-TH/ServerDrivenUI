import Foundation

protocol Validator {
    func validate(value: FieldValue, field: FormField) -> ValidationResult
}
