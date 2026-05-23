import XCTest
@testable import ServerDrivenUI

final class DefaultValueTests: XCTestCase {

    func decodeWrapper(_ json: String) throws -> Wrapper {
        try JSONDecoder().decode(Wrapper.self, from: Data(json.utf8))
    }

    struct Wrapper: Decodable {
        let value: FieldDefault
    }

    func testStringDefault() throws {
        let w = try decodeWrapper("""
        { "value": "hello" }
        """)
        XCTAssertEqual(w.value, .string("hello"))
    }

    func testBoolDefault() throws {
        let w = try decodeWrapper("""
        { "value": true }
        """)
        XCTAssertEqual(w.value, .bool(true))
    }

    func testStringArrayDefault() throws {
        let w = try decodeWrapper("""
        { "value": ["a", "b"] }
        """)
        XCTAssertEqual(w.value, .strings(["a", "b"]))
    }

    func testNullDefault() throws {
        let w = try decodeWrapper("""
        { "value": null }
        """)
        XCTAssertEqual(w.value, .null)
    }
}
