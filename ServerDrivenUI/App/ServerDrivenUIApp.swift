import SwiftUI

@main
struct ServerDrivenUIApp: App {
    @StateObject private var viewModel = FormViewModel(loader: BundleFormLoader())
    private let renderer = SwiftUIFormRenderer()

    var body: some Scene {
        WindowGroup {
            renderer.render(viewModel: viewModel)
        }
    }
}
