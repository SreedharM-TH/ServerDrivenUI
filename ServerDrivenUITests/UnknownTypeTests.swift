import XCTest
@testable import ServerDrivenUI

final class UnknownTypeTests: XCTestCase {

    func testUnknownTypeDecodesAsUnsupportedWithoutCrashing() throws {
        let json = """
        { "id": "color", "order": 6, "type": "COLOR_PICKER", "label": "Color" }
        """
        let field = try JSONDecoder().decode(FormField.self, from: Data(json.utf8))
        guard case .unsupported(let raw) = field.kind else {
            return XCTFail("Expected .unsupported, got \(field.kind)")
        }
        XCTAssertEqual(raw, "COLOR_PICKER")
        XCTAssertFalse(field.kind.isRenderable)
    }

    func testSchemaFiltersUnsupportedFromRenderable() throws {
        let json = """
        {
          "theme": { "background_color": "#FFF", "text_color": "#000", "border_color": "#CCC", "error_color": "#F00" },
          "form_title": "x",
          "fields": [
            { "id": "a", "order": 1, "type": "TEXT", "subtype": "PLAIN", "label": "A" },
            { "id": "b", "order": 2, "type": "COLOR_PICKER", "label": "B" }
          ]
        }
        """
        let schema = try JSONDecoder().decode(FormSchema.self, from: Data(json.utf8))
        XCTAssertEqual(schema.fields.count, 2)
        XCTAssertEqual(schema.renderableFieldsSortedByOrder.count, 1)
        XCTAssertEqual(schema.renderableFieldsSortedByOrder.first?.id, "a")
    }
}
