import SwiftUI

@main
struct ServerDrivenUIApp: App {
    @StateObject private var viewModel: FormViewModel
    private let renderer = SwiftUIFormRenderer()

    init() {
        let stack = CoreDataStack()
        let persistence = CoreDataFormStatePersistence(stack: stack)
        _viewModel = StateObject(
            wrappedValue: FormViewModel(
                loader: BundleFormLoader(),
                persistence: persistence
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            renderer.render(viewModel: viewModel)
        }
    }
}
