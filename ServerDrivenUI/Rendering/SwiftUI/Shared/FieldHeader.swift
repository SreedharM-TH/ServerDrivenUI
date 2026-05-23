import SwiftUI

struct FieldHeader: View {
    @Environment(\.appColors) private var colors

    let label: String
    let required: Bool
    let supporting: String?
    let error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !label.isEmpty {
                HStack(spacing: 4) {
                    Text(label).font(AppFonts.label).foregroundColor(colors.text)
                    if required {
                        Text("*")
                            .font(AppFonts.label)
                            .foregroundColor(colors.error)
                            .accessibilityLabel("required")
                    }
                }
            }
            if let error, !error.isEmpty {
                Text(error).font(AppFonts.caption).foregroundColor(colors.error)
            } else if let supporting, !supporting.isEmpty {
                Text(supporting).font(AppFonts.caption).foregroundColor(colors.text.opacity(0.7))
            }
        }
    }
}
