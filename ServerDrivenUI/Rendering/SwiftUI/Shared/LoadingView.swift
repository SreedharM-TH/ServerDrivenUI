import SwiftUI

struct LoadingView: View {
    @Environment(\.appColors) private var colors

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading form…").font(AppFonts.body).foregroundColor(colors.text.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
    }
}
