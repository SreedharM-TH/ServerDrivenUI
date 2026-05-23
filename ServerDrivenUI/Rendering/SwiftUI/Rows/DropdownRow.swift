import SwiftUI

struct DropdownRow: View {
    @Environment(\.appColors) private var colors
    @EnvironmentObject private var viewModel: FormViewModel

    let field: FormField
    let spec: DropdownSpec

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldHeader(label: field.label,
                        required: field.required,
                        supporting: spec.options.isEmpty ? "No options available." : nil,
                        error: viewModel.error(for: field))

            control
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(viewModel.error(for: field) == nil ? colors.border : colors.error, lineWidth: 1)
                )
                .background(colors.background)
        }
    }

    @ViewBuilder
    private var control: some View {
        if spec.options.isEmpty {
            HStack {
                Text("—").foregroundColor(colors.text.opacity(0.5))
                Spacer()
                Image(systemName: "chevron.down").foregroundColor(colors.text.opacity(0.3))
            }
        } else if spec.allowMultiple {
            multiSelectMenu
        } else {
            singleSelectMenu
        }
    }

    private var singleSelectMenu: some View {
        let selectedId: String? = {
            if case .single(let s) = viewModel.value(for: field) { return s }
            return nil
        }()
        let selectedLabel = spec.options.first(where: { $0.id == selectedId })?.label

        return Menu {
            ForEach(spec.options) { option in
                Button {
                    viewModel.setValue(.single(option.id), for: field)
                } label: {
                    HStack {
                        Text(option.label)
                        if option.id == selectedId {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(selectedLabel ?? "Select…")
                    .foregroundColor(selectedLabel == nil ? colors.text.opacity(0.5) : colors.text)
                Spacer()
                Image(systemName: "chevron.down").foregroundColor(colors.text.opacity(0.6))
            }
        }
    }

    private var multiSelectMenu: some View {
        let selectedIds: Set<String> = {
            if case .multi(let set) = viewModel.value(for: field) { return set }
            return []
        }()
        let labels = spec.options
            .filter { selectedIds.contains($0.id) }
            .map(\.label)

        return Menu {
            ForEach(spec.options) { option in
                Button {
                    toggle(option.id, in: selectedIds)
                } label: {
                    HStack {
                        Text(option.label)
                        if selectedIds.contains(option.id) {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(labels.isEmpty ? "Select…" : labels.joined(separator: ", "))
                    .foregroundColor(labels.isEmpty ? colors.text.opacity(0.5) : colors.text)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down").foregroundColor(colors.text.opacity(0.6))
            }
        }
    }

    private func toggle(_ id: String, in current: Set<String>) {
        var next = current
        if next.contains(id) { next.remove(id) } else { next.insert(id) }
        viewModel.setValue(.multi(next), for: field)
    }
}
