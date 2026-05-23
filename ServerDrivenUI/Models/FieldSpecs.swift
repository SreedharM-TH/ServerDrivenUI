import Foundation

struct TextSpec: Equatable {
    let subtype: FieldSubtype
    let placeholder: String?
    let maxLength: Int?
    let regex: String?
    let defaultValue: String?
}

struct DropdownSpec: Equatable {
    let options: [DropdownOption]
    let allowMultiple: Bool
    let defaultValues: [String]
    let defaultValue: String?
}

struct ToggleSpec: Equatable {
    let defaultValue: Bool
}

struct CheckboxSpec: Equatable {
    let metadata: [String: String]
    let clickableTextColor: String?
    let defaultValue: Bool
}
