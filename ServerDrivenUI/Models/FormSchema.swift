import Foundation

struct FormSchema: Decodable, Equatable {
    let theme: Theme
    let formTitle: String
    let fields: [FormField]

    enum CodingKeys: String, CodingKey {
        case theme
        case formTitle = "form_title"
        case fields
    }

    init(theme: Theme, formTitle: String, fields: [FormField]) {
        self.theme = theme
        self.formTitle = formTitle
        self.fields = fields
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.theme = (try? c.decode(Theme.self, forKey: .theme)) ?? .fallback
        self.formTitle = (try? c.decode(String.self, forKey: .formTitle)) ?? ""

        if c.contains(.fields) {
            let lossy = try c.decode(LossyArray<FormField>.self, forKey: .fields)
            self.fields = lossy.wrappedValue
        } else {
            self.fields = []
        }
    }

    var renderableFieldsSortedByOrder: [FormField] {
        fields
            .filter { $0.kind.isRenderable }
            .enumerated()
            .sorted { lhs, rhs in
                if lhs.element.order != rhs.element.order { return lhs.element.order < rhs.element.order }
                return lhs.offset < rhs.offset
            }
            .map { $0.element }
    }
}
