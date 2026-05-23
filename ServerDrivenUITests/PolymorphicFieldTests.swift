import XCTest
@testable import ServerDrivenUI

final class PolymorphicFieldTests: XCTestCase {

    func decode(_ json: String) throws -> FormField {
        try JSONDecoder().decode(FormField.self, from: Data(json.utf8))
    }

    func testDecodeTextPlain() throws {
        let json = """
        { "id": "name", "order": 1, "type": "TEXT", "subtype": "PLAIN", "label": "Name", "required": true }
        """
        let field = try decode(json)
        XCTAssertEqual(field.id, "name")
        XCTAssertEqual(field.order, 1)
        XCTAssertTrue(field.required)
        guard case .text(let spec) = field.kind else { return XCTFail("Expected text kind") }
        XCTAssertEqual(spec.subtype, .plain)
    }

    func testDecodeTextWithMaxLengthAndDefault() throws {
        let json = """
        { "id": "n", "order": 2, "type": "TEXT", "subtype": "PLAIN", "label": "N", "default_value": "hello", "max_length": 10 }
        """
        let field = try decode(json)
        guard case .text(let spec) = field.kind else { return XCTFail("Expected text kind") }
        XCTAssertEqual(spec.maxLength, 10)
        XCTAssertEqual(spec.defaultValue, "hello")
    }

    func testDecodeTextUnknownSubtypeFallsBackToPlain() throws {
        let json = """
        { "id": "n", "order": 3, "type": "TEXT", "subtype": "EMOJI", "label": "N" }
        """
        let field = try decode(json)
        guard case .text(let spec) = field.kind else { return XCTFail("Expected text kind") }
        XCTAssertEqual(spec.subtype, .plain)
    }

    func testDecodeDropdownMulti() throws {
        let json = """
        {
          "id": "nw", "order": 4, "type": "DROPDOWN", "label": "Networks",
          "allow_multiple": true, "default_values": ["a", "b"],
          "options": [{"id": "a", "label": "A"}, {"id": "b", "label": "B"}]
        }
        """
        let field = try decode(json)
        guard case .dropdown(let spec) = field.kind else { return XCTFail("Expected dropdown") }
        XCTAssertTrue(spec.allowMultiple)
        XCTAssertEqual(spec.defaultValues, ["a", "b"])
        XCTAssertEqual(spec.options.count, 2)
    }

    func testDecodeDropdownEmptyOptionsDoesNotCrash() throws {
        let json = """
        { "id": "ba", "order": 1, "type": "DROPDOWN", "label": "Billing", "required": true, "options": [] }
        """
        let field = try decode(json)
        guard case .dropdown(let spec) = field.kind else { return XCTFail("Expected dropdown") }
        XCTAssertEqual(spec.options.count, 0)
        XCTAssertFalse(spec.allowMultiple)
    }

    func testDecodeToggleDefaultTrue() throws {
        let json = """
        { "id": "ai", "order": 5, "type": "TOGGLE", "label": "AI", "default_value": true }
        """
        let field = try decode(json)
        guard case .toggle(let spec) = field.kind else { return XCTFail("Expected toggle") }
        XCTAssertTrue(spec.defaultValue)
    }

    func testDecodeCheckboxWithMetadata() throws {
        let json = """
        {
          "id": "tos", "order": 6, "type": "CHECKBOX",
          "label": "I agree to the Terms of Service.", "required": true,
          "metadata": { "Terms of Service": "https://example.com/terms" },
          "clickable_text_color": "#BB86FC"
        }
        """
        let field = try decode(json)
        guard case .checkbox(let spec) = field.kind else { return XCTFail("Expected checkbox") }
        XCTAssertEqual(spec.metadata["Terms of Service"], "https://example.com/terms")
        XCTAssertEqual(spec.clickableTextColor, "#BB86FC")
    }
}
