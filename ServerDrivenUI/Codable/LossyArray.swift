import Foundation

@propertyWrapper
struct LossyArray<Element: Decodable>: Decodable {
    var wrappedValue: [Element]

    init(wrappedValue: [Element]) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements: [Element] = []
        elements.reserveCapacity(container.count ?? 0)

        while !container.isAtEnd {
            do {
                let element = try container.decode(Element.self)
                elements.append(element)
            } catch {
                // Advance past the malformed element so currentIndex moves forward.
                _ = try? container.decode(AnyDecodableSkip.self)
                #if DEBUG
                print("[LossyArray] Skipped element due to decoding error: \(error)")
                #endif
            }
        }

        self.wrappedValue = elements
    }
}
