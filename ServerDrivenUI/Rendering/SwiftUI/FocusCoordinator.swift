import Foundation

/// Derives the ordered list of focusable text-field IDs from the visible fields,
/// and provides previous/next navigation helpers.
struct FocusCoordinator {
    let orderedFocusableIDs: [String]

    init(fields: [FormField]) {
        self.orderedFocusableIDs = fields.compactMap { field in
            if case .text = field.kind { return field.id }
            return nil
        }
    }

    func next(after id: String?) -> String? {
        guard let id, let idx = orderedFocusableIDs.firstIndex(of: id),
              idx + 1 < orderedFocusableIDs.count else { return nil }
        return orderedFocusableIDs[idx + 1]
    }

    func previous(before id: String?) -> String? {
        guard let id, let idx = orderedFocusableIDs.firstIndex(of: id),
              idx - 1 >= 0 else { return nil }
        return orderedFocusableIDs[idx - 1]
    }

    func isFirst(_ id: String?) -> Bool {
        guard let id else { return true }
        return orderedFocusableIDs.first == id
    }

    func isLast(_ id: String?) -> Bool {
        guard let id else { return true }
        return orderedFocusableIDs.last == id
    }
}
