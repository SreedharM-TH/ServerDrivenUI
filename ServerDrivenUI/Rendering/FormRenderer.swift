import Foundation

/// Engine seam between a parsed `FormSchema` and an output UI representation.
/// SwiftUI conforms via `SwiftUIFormRenderer`; a future UIKit engine would
/// conform with `Output == UIViewController` (see Rendering/UIKit/README.md).
protocol FormRenderer {
    associatedtype Output
    @MainActor func render(viewModel: FormViewModel) -> Output
}
