import SwiftUI

struct CheckboxRow: View {
    @Environment(\.appColors) private var colors
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var viewModel: FormViewModel

    let field: FormField
    let spec: CheckboxSpec

    private var isChecked: Bool {
        if case .bool(let b) = viewModel.value(for: field) { return b }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    viewModel.setValue(.bool(!isChecked), for: field)
                } label: {
                    Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                        .font(.system(size: 22))
                        .foregroundColor(isChecked ? colors.accent : colors.border)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(field.label)
                .accessibilityAddTraits(isChecked ? [.isSelected] : [])

                labelView
                    .font(AppFonts.body)
                    .foregroundColor(colors.text)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let error = viewModel.error(for: field) {
                Text(error)
                    .font(AppFonts.caption)
                    .foregroundColor(colors.error)
                    .padding(.leading, 34)
            }
        }
    }

    @ViewBuilder
    private var labelView: some View {
        if spec.metadata.isEmpty {
            Text(field.label)
        } else {
            Text(buildAttributed())
                .environment(\.openURL, OpenURLAction { url in
                    openURL(url)
                    return .handled
                })
        }
    }

    private func buildAttributed() -> AttributedString {
        var attributed = AttributedString(field.label)
        let linkColor = spec.clickableTextColor.flatMap(Color.init(hex:)) ?? colors.accent

        for (substring, urlString) in spec.metadata {
            guard let url = URL(string: urlString),
                  let range = attributed.range(of: substring) else { continue }
            attributed[range].link = url
            attributed[range].foregroundColor = linkColor
            attributed[range].underlineStyle = .single
        }
        return attributed
    }
}
