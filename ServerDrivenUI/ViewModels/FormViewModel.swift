import Foundation
import SwiftUI

@MainActor
final class FormViewModel: ObservableObject {
    @Published private(set) var state: LoadingState = .idle
    @Published var values: [String: FieldValue] = [:]
    @Published private(set) var errors: [String: String] = [:]

    private let loader: FormSchemaLoader
    private let persistence: FormStatePersistence?
    private let validators: [Validator]
    private let persistDebounce: Duration

    private var persistTask: Task<Void, Never>?

    init(loader: FormSchemaLoader,
         persistence: FormStatePersistence? = nil,
         persistDebounce: Duration = .milliseconds(300),
         validators: [Validator] = [
            DropdownAvailabilityValidator(),
            RequiredValidator(),
            MaxLengthValidator(),
            URLFormatValidator(),
            RegexValidator()
         ]) {
        self.loader = loader
        self.persistence = persistence
        self.persistDebounce = persistDebounce
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
            let draft = (try? await persistence?.load()) ?? [:]
            primeValues(from: schema, draft: draft)
            if schema.renderableFieldsSortedByOrder.isEmpty {
                state = .empty
            } else {
                state = .loaded(schema)
            }
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
        if case .text(let spec) = field.kind, case .text(let s) = value, let limit = spec.maxLength {
            values[field.id] = .text(String(s.prefix(limit)))
        } else {
            values[field.id] = value
        }
        errors[field.id] = nil
        schedulePersist()
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

        // Submission complete — drop the draft so a re-launch starts from JSON defaults.
        persistTask?.cancel()
        if let persistence {
            Task { try? await persistence.clear() }
        }

        return output
    }

    /// Debounced fire-and-forget save of the current `values` snapshot.
    /// Cancellation gives us the debounce: each edit cancels the prior pending
    /// save and starts a new one. Only the final write within a burst lands.
    private func schedulePersist() {
        guard let persistence else { return }
        persistTask?.cancel()
        let snapshot = values
        let delay = persistDebounce
        persistTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            try? await persistence.save(snapshot)
            self?.persistTask = nil
        }
    }

    private func primeValues(from schema: FormSchema, draft: [String: FieldValue]) {
        var seeded: [String: FieldValue] = [:]
        for field in schema.renderableFieldsSortedByOrder {
            if let p = draft[field.id], let normalized = normalize(p, for: field) {
                seeded[field.id] = normalized
            } else {
                seeded[field.id] = defaultValue(for: field)
            }
        }
        values = seeded
        // primeValues runs during hydration — do NOT schedulePersist here, that
        // would re-persist the just-loaded draft and serve no purpose.
    }

    /// Coerce a draft value to fit the current field's constraints, since the
    /// JSON schema may have changed since the draft was captured (max_length
    /// lowered, options removed, etc.). Returns nil if the draft doesn't make
    /// sense for the current field kind — caller falls back to the default.
    private func normalize(_ persisted: FieldValue, for field: FormField) -> FieldValue? {
        switch (field.kind, persisted) {
        case (.text(let spec), .text(let s)):
            if let limit = spec.maxLength { return .text(String(s.prefix(limit))) }
            return .text(s)
        case (.dropdown(let spec), .single(let id)):
            guard !spec.allowMultiple else { return nil }
            let valid = Set(spec.options.map(\.id))
            return .single(id.flatMap { valid.contains($0) ? $0 : nil })
        case (.dropdown(let spec), .multi(let set)):
            guard spec.allowMultiple else { return nil }
            let valid = Set(spec.options.map(\.id))
            return .multi(set.intersection(valid))
        case (.toggle, .bool(let b)):
            return .bool(b)
        case (.checkbox, .bool(let b)):
            return .bool(b)
        default:
            return nil
        }
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
