import Foundation

struct FormField: Decodable, Identifiable, Equatable {
    let id: String
    let order: Int
    let label: String
    let required: Bool
    let errorMessage: String?
    let kind: FieldKind

    enum CodingKeys: String, CodingKey {
        case id, order, type, label, required
        case errorMessage = "error_message"
        case subtype, placeholder
        case maxLength = "max_length"
        case regex
        case defaultValue = "default_value"
        case defaultValues = "default_values"
        case options
        case allowMultiple = "allow_multiple"
        case metadata
        case clickableTextColor = "clickable_text_color"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.order = (try? c.decode(Int.self, forKey: .order)) ?? .max
        self.label = (try? c.decode(String.self, forKey: .label)) ?? ""
        self.required = (try? c.decode(Bool.self, forKey: .required)) ?? false
        self.errorMessage = try? c.decode(String.self, forKey: .errorMessage)

        let rawType = try c.decode(String.self, forKey: .type)
        let defaultValue = try? c.decode(FieldDefault.self, forKey: .defaultValue)

        switch rawType.uppercased() {
        case "TEXT":
            let subtype = (try? c.decode(FieldSubtype.self, forKey: .subtype)) ?? .plain
            let placeholder = try? c.decode(String.self, forKey: .placeholder)
            let maxLength = try? c.decode(Int.self, forKey: .maxLength)
            let regex = try? c.decode(String.self, forKey: .regex)
            self.kind = .text(TextSpec(
                subtype: subtype,
                placeholder: placeholder,
                maxLength: maxLength.flatMap { $0 > 0 ? $0 : nil },
                regex: regex,
                defaultValue: defaultValue?.asString
            ))

        case "DROPDOWN":
            let options = (try? c.decode([DropdownOption].self, forKey: .options)) ?? []
            let allowMultiple = (try? c.decode(Bool.self, forKey: .allowMultiple)) ?? false
            let defaultValues = (try? c.decode([String].self, forKey: .defaultValues)) ?? (defaultValue?.asStrings ?? [])
            self.kind = .dropdown(DropdownSpec(
                options: options,
                allowMultiple: allowMultiple,
                defaultValues: defaultValues,
                defaultValue: defaultValue?.asString
            ))

        case "TOGGLE":
            self.kind = .toggle(ToggleSpec(defaultValue: defaultValue?.asBool ?? false))

        case "CHECKBOX":
            let metadata = (try? c.decode([String: String].self, forKey: .metadata)) ?? [:]
            let clickableTextColor = try? c.decode(String.self, forKey: .clickableTextColor)
            self.kind = .checkbox(CheckboxSpec(
                metadata: metadata,
                clickableTextColor: clickableTextColor,
                defaultValue: defaultValue?.asBool ?? false
            ))

        default:
            self.kind = .unsupported(rawType: rawType)
        }
    }

    init(id: String, order: Int, label: String, required: Bool, errorMessage: String?, kind: FieldKind) {
        self.id = id
        self.order = order
        self.label = label
        self.required = required
        self.errorMessage = errorMessage
        self.kind = kind
    }
}
