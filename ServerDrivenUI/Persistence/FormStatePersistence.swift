import Foundation

/// Persists an in-progress draft of the form's `[fieldId: FieldValue]` state.
/// This is draft-recovery storage (think Gmail drafts): captured continuously
/// while the user is editing, then cleared once the form is successfully
/// submitted. It is *not* a record of past submissions.
protocol FormStatePersistence {
    func load() async throws -> [String: FieldValue]
    func save(_ values: [String: FieldValue]) async throws
    func clear() async throws
}
