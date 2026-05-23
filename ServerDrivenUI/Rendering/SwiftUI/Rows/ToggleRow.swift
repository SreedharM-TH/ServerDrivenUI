import SwiftUI

struct ToggleRow: View {
    @Environment(\.appColors) private var colors
    @EnvironmentObject private var viewModel: FormViewModel

    let field: FormField

    private var binding: Binding<Bool> {
        Binding(
            get: {
                if case .bool(let b) = viewModel.value(for: field) { return b }
                return false
            },
            set: { viewModel.setValue(.bool($0), for: field) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: binding) {
                Text(field.label).font(AppFonts.body).foregroundColor(colors.text)
            }
            .tint(colors.accent)

            if let error = viewModel.error(for: field) {
                Text(error).font(AppFonts.caption).foregroundColor(colors.error)
            }
        }
    }
}
