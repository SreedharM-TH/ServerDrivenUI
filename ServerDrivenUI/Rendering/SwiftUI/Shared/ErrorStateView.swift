import SwiftUI

struct ErrorStateView: View {
    @Environment(\.appColors) private var colors

    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(colors.error)
            Text(message)
                .font(AppFonts.body)
                .foregroundColor(colors.text)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
                .tint(colors.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
    }
}
