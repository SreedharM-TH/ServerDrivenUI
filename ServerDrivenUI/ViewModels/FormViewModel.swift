import Foundation
import SwiftUI

@MainActor
final class FormViewModel: ObservableObject {
    @Published private(set) var state: LoadingState = .idle
    @Published var values: [String: FieldValue] = [:]
    @Published private(set) var errors: [String: String] = [:]

    private let loader: FormSchemaLoader
    private let validators: [Validator]

    init(loader: FormSchemaLoader,
         validators: [Validator] = [
            DropdownAvailabilityValidator(),
            RequiredValidator(),
            MaxLengthValidator(),
            RegexValidator()
         ]) {
        self.loader = loader
        self.validators = validators
    }

    var renderableFields: [FormField] {
        guard case .loaded(let schema) = state else { return [] }
        return schema.renderableFieldsSortedByOrder
    }

    var schema: FormSchema? {
        if case .loaded(let s) = state { return s }
        return nil
    }

    var appColors: AppColors {
        AppColors(theme: schema?.theme ?? .fallback)
    }

    func load() async {
        state = .loading
        do {
            let schema = try await loader.load()
            if schema.renderableFieldsSortedByOrder.isEmpty {
                state = .empty
            } else {
                state = .loaded(schema)
            }
            primeDefaults(from: schema)
        } catch let error as FormLoadError {
            state = .failure(message: error.errorDescription ?? "Failed to load form.")
        } catch {
            state = .failure(message: error.localizedDescription)
        }
    }

    func value(for field: FormField) -> FieldValue {
        if let v = values[field.id] { return v }
        return defaultValue(for: field)
    }

    func setValue(_ value: FieldValue, for field: FormField) {
        // Clamp text values to max_length up front so the counter stays honest.
        if case .text(let spec) = field.kind, case .text(let s) = value, let limit = spec.maxLength {
            values[field.id] = .text(String(s.prefix(limit)))
        } else {
            values[field.id] = value
        }
        errors[field.id] = nil
    }

    func error(for field: FormField) -> String? {
        errors[field.id]
    }

    @discardableResult
    func validate() -> [String: Any]? {
        guard let schema else { return nil }
        var newErrors: [String: String] = [:]

        for field in schema.renderableFieldsSortedByOrder {
            let value = self.value(for: field)
            for validator in validators {
                let result = validator.validate(value: value, field: field)
                if case .invalid(let message) = result {
                    newErrors[field.id] = message
                    break
                }
            }
        }
        errors = newErrors

        guard newErrors.isEmpty else { return nil }

        var output: [String: Any] = [:]
        for field in schema.renderableFieldsSortedByOrder {
            output[field.id] = self.value(for: field).asJSON
        }
        return output
    }

    private func primeDefaults(from schema: FormSchema) {
        var seeded: [String: FieldValue] = [:]
        for field in schema.renderableFieldsSortedByOrder {
            seeded[field.id] = defaultValue(for: field)
        }
        values = seeded
    }

    private func defaultValue(for field: FormField) -> FieldValue {
        switch field.kind {
        case .text(let spec):
            let raw = spec.defaultValue ?? ""
            if let limit = spec.maxLength {
                return .text(String(raw.prefix(limit)))
            }
            return .text(raw)
        case .dropdown(let spec):
            if spec.allowMultiple {
                let validIds = Set(spec.options.map(\.id))
                let seeded = spec.defaultValues.filter { validIds.contains($0) }
                return .multi(Set(seeded))
            } else {
                let validIds = Set(spec.options.map(\.id))
                let candidate = spec.defaultValue ?? spec.defaultValues.first
                if let candidate, validIds.contains(candidate) {
                    return .single(candidate)
                }
                return .single(nil)
            }
        case .toggle(let spec):
            return .bool(spec.defaultValue)
        case .checkbox(let spec):
            return .bool(spec.defaultValue)
        case .unsupported:
            return .text("")
        }
    }
}
