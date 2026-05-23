import SwiftUI

struct FormView: View {
    @ObservedObject var viewModel: FormViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                LoadingView()
            case .empty:
                EmptyStateView()
            case .failure(let message):
                ErrorStateView(message: message) {
                    Task { await viewModel.load() }
                }
            case .loaded(let schema):
                FormContentView(schema: schema)
                    .environmentObject(viewModel)
            }
        }
        .environment(\.appColors, viewModel.appColors)
        .task {
            if case .idle = viewModel.state {
                await viewModel.load()
            }
        }
    }
}
