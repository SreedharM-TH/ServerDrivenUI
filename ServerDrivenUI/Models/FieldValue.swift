import Foundation

enum FieldValue: Equatable {
    case text(String)
    case bool(Bool)
    case single(String?)
    case multi(Set<String>)

    var asJSON: Any {
        switch self {
        case .text(let s): return s
        case .bool(let b): return b
        case .single(let s): return s ?? NSNull()
        case .multi(let set): return Array(set).sorted()
        }
    }

    var isEmpty: Bool {
        switch self {
        case .text(let s): return s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .bool(let b): return !b
        case .single(let s): return (s ?? "").isEmpty
        case .multi(let set): return set.isEmpty
        }
    }
}
