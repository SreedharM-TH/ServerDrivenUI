import Foundation

/// Codable conformance for `FieldValue` so it can be encoded to `Data`
/// and stored as a single blob attribute on `PersistedFieldValue`.
/// Uses a `kind` discriminator + `value` payload shape.
extension FieldValue: Codable {
    private enum Kind: String, Codable {
        case text, bool, single, multi
    }
    private enum CodingKeys: String, CodingKey {
        case kind, value
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let s):
            try c.encode(Kind.text, forKey: .kind)
            try c.encode(s, forKey: .value)
        case .bool(let b):
            try c.encode(Kind.bool, forKey: .kind)
            try c.encode(b, forKey: .value)
        case .single(let s):
            try c.encode(Kind.single, forKey: .kind)
            try c.encodeIfPresent(s, forKey: .value)
        case .multi(let set):
            try c.encode(Kind.multi, forKey: .kind)
            try c.encode(Array(set).sorted(), forKey: .value)
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(Kind.self, forKey: .kind)
        switch kind {
        case .text:
            self = .text(try c.decode(String.self, forKey: .value))
        case .bool:
            self = .bool(try c.decode(Bool.self, forKey: .value))
        case .single:
            self = .single(try c.decodeIfPresent(String.self, forKey: .value))
        case .multi:
            self = .multi(Set(try c.decode([String].self, forKey: .value)))
        }
    }
}
