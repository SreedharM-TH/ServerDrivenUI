import Foundation

/// Detects the contradictory case where the server marks a DROPDOWN as
/// `required` but ships an empty `options` array — the user has nothing to
/// pick, so the field can never satisfy `required` on its own.
/// Emits a misconfiguration message so the user knows the issue is upstream,
/// not a missed input on their end. Runs before `RequiredValidator` in the
/// view model's validator chain so its message takes precedence.
struct DropdownAvailabilityValidator: Validator {
    func validate(value: FieldValue, field: FormField) -> ValidationResult {
        guard case .dropdown(let spec) = field.kind,
              field.required,
              spec.options.isEmpty else {
            return .valid
        }
        let label = field.label.isEmpty ? "This field" : field.label
        return .invalid(message: "\(label) is unavailable right now. Please contact support.")
    }
}
