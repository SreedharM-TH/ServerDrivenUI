import SwiftUI

struct SwiftUIFormRenderer: FormRenderer {
    typealias Output = AnyView

    @MainActor
    func render(viewModel: FormViewModel) -> AnyView {
        AnyView(FormView(viewModel: viewModel))
    }
}
