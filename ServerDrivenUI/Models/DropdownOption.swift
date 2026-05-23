import Foundation

struct DropdownOption: Decodable, Identifiable, Hashable {
    let id: String
    let label: String
}
