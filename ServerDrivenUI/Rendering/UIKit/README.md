# UIKit renderer

This directory exists to document the engine seam between the parsed JSON
model and a UIKit output. The current submission ships only the SwiftUI
engine (`Rendering/SwiftUI`), per assignment scope.

A future UIKit renderer would conform to `FormRenderer` with
`Output == UIViewController`, consuming the same `FormViewModel` and emitting
UIKit views. The interop bridge between the two engines is the
`FormRenderer` protocol itself — no UIHostingController shim is needed at the
engine boundary, only at integration points.
