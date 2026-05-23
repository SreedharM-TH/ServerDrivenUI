import Foundation

struct Theme: Decodable, Equatable {
    let backgroundColor: String
    let textColor: String
    let borderColor: String
    let errorColor: String

    enum CodingKeys: String, CodingKey {
        case backgroundColor = "background_color"
        case textColor = "text_color"
        case borderColor = "border_color"
        case errorColor = "error_color"
    }

    static let fallback = Theme(
        backgroundColor: "#FFFFFF",
        textColor: "#111827",
        borderColor: "#D1D5DB",
        errorColor: "#B91C1C"
    )

    init(backgroundColor: String, textColor: String, borderColor: String, errorColor: String) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.borderColor = borderColor
        self.errorColor = errorColor
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.backgroundColor = (try? c.decode(String.self, forKey: .backgroundColor)) ?? Theme.fallback.backgroundColor
        self.textColor = (try? c.decode(String.self, forKey: .textColor)) ?? Theme.fallback.textColor
        self.borderColor = (try? c.decode(String.self, forKey: .borderColor)) ?? Theme.fallback.borderColor
        self.errorColor = (try? c.decode(String.self, forKey: .errorColor)) ?? Theme.fallback.errorColor
    }
}
