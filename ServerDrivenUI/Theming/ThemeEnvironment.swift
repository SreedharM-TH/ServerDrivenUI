import SwiftUI

private struct AppColorsKey: EnvironmentKey {
    static let defaultValue: AppColors = .default
}

extension EnvironmentValues {
    var appColors: AppColors {
        get { self[AppColorsKey.self] }
        set { self[AppColorsKey.self] = newValue }
    }
}
