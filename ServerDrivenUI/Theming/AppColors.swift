import SwiftUI

struct AppColors {
    let background: Color
    let text: Color
    let border: Color
    let error: Color
    let accent: Color

    static let `default` = AppColors(
        background: Color(.systemBackground),
        text: Color(.label),
        border: Color(.separator),
        error: Color(.systemRed),
        accent: Color.accentColor
    )

    init(background: Color, text: Color, border: Color, error: Color, accent: Color) {
        self.background = background
        self.text = text
        self.border = border
        self.error = error
        self.accent = accent
    }

    init(theme: Theme) {
        self.background = Color(hex: theme.backgroundColor) ?? AppColors.default.background
        self.text = Color(hex: theme.textColor) ?? AppColors.default.text
        self.border = Color(hex: theme.borderColor) ?? AppColors.default.border
        self.error = Color(hex: theme.errorColor) ?? AppColors.default.error
        self.accent = Color(hex: theme.borderColor) ?? AppColors.default.accent
    }
}
