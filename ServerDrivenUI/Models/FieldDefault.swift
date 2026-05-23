import Foundation

enum FieldDefault: Decodable, Equatable {
    case string(String)
    case bool(Bool)
    case strings([String])
    case null

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() {
            self = .null
        } else if let b = try? c.decode(Bool.self) {
            self = .bool(b)
        } else if let arr = try? c.decode([String].self) {
            self = .strings(arr)
        } else if let s = try? c.decode(String.self) {
            self = .string(s)
        } else {
            self = .null
        }
    }

    var asString: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    var asBool: Bool? {
        if case .bool(let b) = self { return b }
        return nil
    }

    var asStrings: [String]? {
        if case .strings(let a) = self { return a }
        return nil
    }
}
