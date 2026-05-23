import SwiftUI

struct TextRow: View {
    @Environment(\.appColors) private var colors
    @EnvironmentObject private var viewModel: FormViewModel

    let field: FormField
    let spec: TextSpec
    let focus: FocusState<String?>.Binding

    private var textBinding: Binding<String> {
        Binding(
            get: {
                if case .text(let s) = viewModel.value(for: field) { return s }
                return ""
            },
            set: { viewModel.setValue(.text($0), for: field) }
        )
    }

    private var currentText: String {
        if case .text(let s) = viewModel.value(for: field) { return s }
        return ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldHeader(label: field.label,
                        required: field.required,
                        supporting: nil,
                        error: viewModel.error(for: field))

            inputField
                .focused(focus, equals: field.id)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(viewModel.error(for: field) == nil ? colors.border : colors.error, lineWidth: 1)
                )
                .foregroundColor(colors.text)
                .background(colors.background)

            if let limit = spec.maxLength {
                Text("\(currentText.count)/\(limit)")
                    .font(AppFonts.counter)
                    .foregroundColor(colors.text.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    @ViewBuilder
    private var inputField: some View {
        switch spec.subtype {
        case .plain:
            TextField(spec.placeholder ?? "", text: textBinding)
                .textInputAutocapitalization(.sentences)
        case .multiline:
            TextField(spec.placeholder ?? "", text: textBinding, axis: .vertical)
                .lineLimit(3...8)
        case .number:
            TextField(spec.placeholder ?? "", text: numericBinding)
                .keyboardType(.numberPad)
        case .uri:
            TextField(spec.placeholder ?? "", text: textBinding)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
        case .secure:
            SecureField(spec.placeholder ?? "", text: textBinding)
        }
    }

    private var numericBinding: Binding<String> {
        Binding(
            get: { currentText },
            set: { newValue in
                let filtered = newValue.filter { $0.isNumber || $0 == "." }
                viewModel.setValue(.text(filtered), for: field)
            }
        )
    }
}
