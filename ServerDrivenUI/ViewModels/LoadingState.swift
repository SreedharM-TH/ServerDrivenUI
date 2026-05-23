import Foundation

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded(FormSchema)
    case empty
    case failure(message: String)
}
