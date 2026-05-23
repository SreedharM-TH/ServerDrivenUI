# ServerDrivenUI — Dynamic Form Builder

Single-screen iOS app whose entire UI is driven by a local JSON payload. Built for the Eulerity iOS take-home exercise.

- **Language / UI:** Swift, SwiftUI
- **Minimum deployment target:** iOS 16.0
- **Devices:** iPhone + iPad, portrait + landscape
- **Network:** Fully offline; JSON is loaded from the app bundle
- **Tests:** 30 XCTest cases covering polymorphic decoding, defensive parsing, validation, and theme parsing

## Run

Open `ServerDrivenUI.xcodeproj` in Xcode 16 or newer, select the `ServerDrivenUI` scheme, and Cmd+R. The sample payload at `ServerDrivenUI/Resources/form_schema.json` is the assignment's "all-in-one" test payload — out-of-order fields, an empty options array, an unknown `COLOR_PICKER` type, a `default_value` that exceeds `max_length`, and a checkbox with rich-text metadata links.

To run the tests: Cmd+U, or `xcodebuild test -scheme ServerDrivenUI -destination "platform=iOS Simulator,name=iPhone 17"`.

## Architecture

Three layered engines, separated by folder boundary:

```
JSON file ─► FormSchemaLoader (protocol)
                 │
                 ├─ BundleFormLoader (real, offline)
                 └─ MockFormLoader  (tests)
                 ▼
        FormSchema ─ Theme ─ [FormField]   ← JSON-to-Swift engine
                 │
                 ▼
        FormViewModel (ObservableObject, @MainActor)
          ├─ state: LoadingState           ← idle / loading / loaded / empty / failure
          ├─ values: [String: FieldValue]  ← heterogeneous values keyed by field id
          ├─ errors: [String: String]      ← populated on Save
          └─ validate() / value(for:) / setValue(_:for:)
                 │
                 ▼
        FormRenderer protocol              ← seam between SwiftUI and a future UIKit engine
                 │
                 └─ SwiftUIFormRenderer    ← the one we build
                       └─ FormView → per-kind row views
```

### Folder layout

| Folder | Responsibility |
|---|---|
| `Models/` | JSON→Swift engine. `FormSchema`, `FormField` (struct + nested `FieldKind` enum), specs per type, `FieldDefault`, `FieldValue` |
| `Codable/` | `LossyArray` property wrapper + `AnyDecodableSkip` for graceful per-element decoding |
| `Services/` | `FormSchemaLoader` protocol + `BundleFormLoader` (real) + `MockFormLoader` (tests) + typed `FormLoadError` |
| `Validation/` | `Validator` protocol with `RequiredValidator`, `MaxLengthValidator`, `RegexValidator` — Open/Closed: add new rules without touching the VM |
| `Theming/` | `AppColors` (hex → SwiftUI Color), `AppFonts` type scale, environment key |
| `Utilities/` | `Color(hex:)` initializer |
| `ViewModels/` | `FormViewModel` + `LoadingState` |
| `Rendering/` | `FormRenderer` protocol (interop seam) + `SwiftUI/` engine. A UIKit engine would live in `Rendering/UIKit/` and conform to the same protocol — see the README there. |
| `Resources/` | `form_schema.json` |

### Polymorphic JSON parsing

`FormField` is a value type. The `type` discriminator is read inside `init(from:)` and dispatched to a `FieldKind` enum:

```swift
enum FieldKind {
    case text(TextSpec)
    case dropdown(DropdownSpec)
    case toggle(ToggleSpec)
    case checkbox(CheckboxSpec)
    case unsupported(rawType: String)
}
```

Two layers of defensive decoding:

1. **Unknown `type`** (e.g. `COLOR_PICKER`) — handled inside `FormField.init(from:)`, decoded as `.unsupported(rawType:)`. The renderer filters these out via `FormSchema.renderableFieldsSortedByOrder`.
2. **Malformed elements** (missing required fields, wrong types) — handled at the array level by `@LossyArray`, which catches the per-element decode failure and advances `UnkeyedDecodingContainer.currentIndex` past the bad element via `AnyDecodableSkip`. One bad field never nukes the whole form.

`FieldDefault` is an enum that tries `null` → `Bool` → `[String]` → `String` in that order, so `default_value: true`, `default_value: "x"`, `default_values: ["a","b"]`, and `default_value: null` all decode cleanly.

### Theming

The `Theme` block from JSON (`background_color`, `text_color`, `border_color`, `error_color`) is parsed into `AppColors` via a `Color(hex:)` initializer that handles both `#RRGGBB` and `#RRGGBBAA`. Any unparseable color falls back to the system default. Colors are injected into the SwiftUI view tree through an `EnvironmentKey` (`\.appColors`), so every row picks up theming without prop-drilling.

### iPhone + iPad / portrait + landscape

The form is rendered inside a `ScrollView { VStack }` (not a SwiftUI `Form` — `Form` looks awkward on iPad landscape and fights theming). When `horizontalSizeClass == .regular`, the content is clamped to a 640 pt max width and centered, so it doesn't stretch edge-to-edge on a 13" iPad.

## Component support

| Type | Subtypes / variants | Notes |
|---|---|---|
| `TEXT` | `PLAIN`, `MULTILINE`, `NUMBER`, `URI`, `SECURE` | `max_length` enforced at input time + visible counter. Optional `regex` checked on Save. |
| `DROPDOWN` | Single (Menu) and multi-select (Menu with checkmarks) | UI shows `label`, state tracks `id`. Empty `options` renders disabled with "No options available." Defaults outside the option set are dropped. |
| `TOGGLE` | Standard `Toggle` | Honors `default_value`. |
| `CHECKBOX` | Custom checkbox + rich-text label | `metadata` keys become `AttributedString` `.link` ranges with `clickable_text_color` (or theme accent fallback). Taps open via `Environment(\.openURL)`. |

Each row reads its value via a typed binding into the view model — rows own no state themselves, which is what keeps the engine generic.

### Validation UX

- **Save button** at the bottom of the form. Tapping it runs all validators and either prints the final key-value JSON dump to the Xcode console + shows a confirmation alert, or populates per-field error messages.
- **Errors clear** as the user edits.
- **Four validators today** (`DropdownAvailability`, `Required`, `MaxLength`, `Regex`) — adding a new rule means adding a `Validator` conformance and listing it in the view model's validators array. No other files change. Order matters: the view model breaks on the first invalid result per field, so more specific validators (e.g. `DropdownAvailability`) run before generic ones (e.g. `Required`).

### Focus management

The keyboard toolbar has Previous / Next / Done buttons (via `@FocusState` + `FocusCoordinator`). Cycling order is derived from the renderable text fields sorted by `order` — the focus coordinator is data-driven, not hard-coded.

## Product decisions (not explicitly defined in the brief)

1. **`default_value` longer than `max_length`** — Truncate to `max_length` when seeding the view model, so the character counter is honest from the moment the form appears. The validator still flags the field on Save if the truncated value happens to be empty and the field is required. **Why:** silently dropping the data feels worse than visibly truncating it, and showing "65/20" in the counter would be a worse first impression than "20/20".

2. **Dropdown with an empty `options` array** — Render a disabled control with the supporting text "No options available." If the field is also `required`, a dedicated `DropdownAvailabilityValidator` runs *before* `RequiredValidator` and emits a misconfiguration message — *"<Label> is unavailable right now. Please contact support."* — instead of the generic required error. **Why:** this is a contradictory constraint the user cannot satisfy on their own; surfacing a generic "please select one" error would be misleading. The misconfiguration message signals that the issue is upstream (server side), not user error, and the form remains un-submittable as the server intended.

3. **Validation timing** — On Save only, not as-you-type. **Why:** aggressive inline validation on a server-driven form produces false-positives before the user finishes typing (especially regex). The brief says "on press/validation, the user should clearly understand if they missed a required field" — that maps best to Save-time validation.

4. **Unknown `type`** — Silently filtered out of the renderable list. Logged in `#if DEBUG` so engineers can see it, invisible to end users. **Why:** the brief is explicit ("must not crash, must gracefully ignore"). Logging keeps it diagnosable without showing a phantom row.

## What I'd improve with more time

- **Per-field `Validator` composition** — today the view model wires three validators that each gate on `field.kind` internally. A cleaner shape is a `[FormField → [Validator]]` resolver so each field carries its own validation pipeline.
- **Independent UIKit renderer** — the `FormRenderer` protocol seam is in place, but the matching UIKit engine isn't built. With more time I'd ship `UIKitFormRenderer` returning a `UIViewController` and a small `HostingBridge` so the two engines are interchangeable.
- **Snapshot tests for each row** — XCTest covers parsing and validation thoroughly; the rendering layer is only verified manually. iOS-snapshot or `ViewInspector` would close that gap.
- **Accessibility audit** — VoiceOver labels are reasonable by default (the checkbox row sets `accessibilityAddTraits(.isSelected)`), but a full pass for Dynamic Type and rotor navigation would help.
- **Per-field error during edit, not just Save** — once typing settles (debounced), inline validation for `max_length` already happens implicitly via input clamping. Showing the `regex` error on field blur (not on every keystroke) is the right next step.

## Things I worked through

- **Polymorphic Codable shape** — I considered three approaches: protocol existential (`any FieldProtocol`), class hierarchy, and the single struct + nested enum. The struct+enum pattern won because SwiftUI's `ForEach`/diffing wants value semantics, exhaustive `switch` checking in the renderer is a feature not a bug, and existentials lose `Identifiable`/`Hashable` conformance for free.
- **Per-element error recovery in JSON arrays** — `UnkeyedDecodingContainer.currentIndex` only advances on a *successful* decode. If you `catch` an error from `container.decode`, the cursor stays put and the next iteration re-reads the same broken element. The fix is to decode a throwaway `AnyDecodableSkip` value in the catch branch to advance past it — that's what `LossyArray` does.
- **iPad layout** — first pass used SwiftUI's `Form`. It worked on iPhone but on iPad landscape it stretched edge-to-edge and the section backgrounds fought the theme. Switching to `ScrollView { VStack }` + a `maxWidth` clamp under `.regular` size class was the right move.

## Tests

```
$ xcodebuild test -scheme ServerDrivenUI -destination "platform=iOS Simulator,name=iPhone 17"
…
Executed 30 tests, with 0 failures
```

| Suite | What it covers |
|---|---|
| `PolymorphicFieldTests` | Each field type decodes correctly; unknown subtypes fall back to PLAIN |
| `UnknownTypeTests` | `COLOR_PICKER` decodes as `.unsupported`; renderable list filters it out |
| `LossyArrayTests` | Malformed elements are skipped; ordering is by `order` field, not array index; missing fields array is OK |
| `ThemeDecodingTests` | Hex parsing for 6 and 8 char strings; missing theme keys fall back to defaults |
| `DefaultValueTests` | `default_value` decodes as `String`, `Bool`, `[String]`, or `null` |
| `ValidationTests` | Required + max_length + regex pass/fail paths; multi-select required when empty |
| `FormSchemaDecodingTests` | End-to-end on the "all-in-one" payload + view-model default truncation |

## AI tool usage

This project was built collaboratively with an AI assistant. The interaction log is in `AI_COLLABORATION_LOG.md`.
