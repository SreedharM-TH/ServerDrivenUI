import Foundation

enum FieldKind: Equatable {
    case text(TextSpec)
    case dropdown(DropdownSpec)
    case toggle(ToggleSpec)
    case checkbox(CheckboxSpec)
    case unsupported(rawType: String)

    var isRenderable: Bool {
        if case .unsupported = self { return false }
        return true
    }
}
