import Foundation

/// Built-in baseline validator for TEXT fields with subtype URI.
/// Requires the value to parse as a URL with both a non-empty scheme and a
/// non-empty host (e.g., "https://example.com" passes, "not-a-url" fails,
/// "http://" fails). Scheme is intentionally NOT restricted to http/https —
/// the server can tighten that further via an optional `regex` on the field,
/// which `RegexValidator` enforces after this one.
/// Empty strings are passed through so `RequiredValidator` owns the "missing
/// value" message exclusively.
struct URLFormatValidator: Validator {
    func validate(value: FieldValue, field: FormField) -> ValidationResult {
        guard case .text(let spec) = field.kind, spec.subtype == .uri else { return .valid }
        guard case .text(let text) = value else { return .valid }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .valid }

        guard
            let components = URLComponents(string: trimmed),
            let scheme = components.scheme, !scheme.isEmpty,
            let host = components.host, !host.isEmpty
        else {
            let message = field.errorMessage ?? "\(field.label) must be a valid URL (e.g., https://example.com)."
            return .invalid(message: message)
        }
        return .valid
    }
}
