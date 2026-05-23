import SwiftUI

struct FormContentView: View {
    @Environment(\.appColors) private var colors
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var viewModel: FormViewModel

    @FocusState private var focusedFieldID: String?
    @State private var saveAlert: SaveAlert?

    private struct SaveAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    let schema: FormSchema

    private var coordinator: FocusCoordinator {
        FocusCoordinator(fields: schema.renderableFieldsSortedByOrder)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !schema.formTitle.isEmpty {
                    Text(schema.formTitle)
                        .font(AppFonts.title)
                        .foregroundColor(colors.text)
                        .padding(.top, 8)
                }

                ForEach(schema.renderableFieldsSortedByOrder) { field in
                    rowView(for: field)
                }

                Button(action: save) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(colors.accent)
                .padding(.top, 12)
            }
            .padding(20)
            .frame(maxWidth: contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(colors.background.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .toolbar { keyboardToolbar }
        .alert(item: $saveAlert) { alert in
            Alert(title: Text(alert.title),
                  message: Text(alert.message),
                  dismissButton: .default(Text("OK")))
        }
    }

    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? 640 : .infinity
    }

    @ViewBuilder
    private func rowView(for field: FormField) -> some View {
        switch field.kind {
        case .text(let spec):
            TextRow(field: field, spec: spec, focus: $focusedFieldID)
        case .dropdown(let spec):
            DropdownRow(field: field, spec: spec)
        case .toggle:
            ToggleRow(field: field)
        case .checkbox(let spec):
            CheckboxRow(field: field, spec: spec)
        case .unsupported:
            EmptyView()
        }
    }

    @ToolbarContentBuilder
    private var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Button {
                focusedFieldID = coordinator.previous(before: focusedFieldID)
            } label: { Image(systemName: "chevron.up") }
            .disabled(coordinator.isFirst(focusedFieldID))

            Button {
                focusedFieldID = coordinator.next(after: focusedFieldID)
            } label: { Image(systemName: "chevron.down") }
            .disabled(coordinator.isLast(focusedFieldID))

            Spacer()

            Button("Done") { focusedFieldID = nil }
        }
    }

    private func save() {
        focusedFieldID = nil
        if let payload = viewModel.validate() {
            let pretty = (try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]))
                .flatMap { String(data: $0, encoding: .utf8) } ?? "\(payload)"
            print("[Form Saved]\n\(pretty)")
            saveAlert = SaveAlert(title: "Form submitted", message: pretty)
        } else {
            let count = viewModel.errors.count
            saveAlert = SaveAlert(title: "Please fix the form",
                                  message: "\(count) field\(count == 1 ? "" : "s") need attention.")
        }
    }
}
