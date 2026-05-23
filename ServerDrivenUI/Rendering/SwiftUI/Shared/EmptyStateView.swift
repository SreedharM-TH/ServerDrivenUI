import SwiftUI

struct EmptyStateView: View {
    @Environment(\.appColors) private var colors

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(colors.text.opacity(0.5))
            Text("No fields to display.")
                .font(AppFonts.body)
                .foregroundColor(colors.text.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
    }
}
