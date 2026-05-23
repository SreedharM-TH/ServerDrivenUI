import XCTest
@testable import ServerDrivenUI

final class LossyArrayTests: XCTestCase {

    func testMalformedElementSkippedRestSurvive() throws {
        // The middle element is missing the required "id" key and should be skipped.
        let json = """
        {
          "theme": { "background_color": "#FFF", "text_color": "#000", "border_color": "#CCC", "error_color": "#F00" },
          "form_title": "x",
          "fields": [
            { "id": "a", "order": 1, "type": "TEXT", "subtype": "PLAIN", "label": "A" },
            { "order": 2, "type": "TEXT", "subtype": "PLAIN", "label": "Broken" },
            { "id": "c", "order": 3, "type": "TEXT", "subtype": "PLAIN", "label": "C" }
          ]
        }
        """
        let schema = try JSONDecoder().decode(FormSchema.self, from: Data(json.utf8))
        XCTAssertEqual(schema.fields.count, 2)
        XCTAssertEqual(schema.fields.map(\.id), ["a", "c"])
    }

    func testOrderingIsByOrderField() throws {
        let json = """
        {
          "theme": { "background_color": "#FFF", "text_color": "#000", "border_color": "#CCC", "error_color": "#F00" },
          "form_title": "x",
          "fields": [
            { "id": "z", "order": 3, "type": "TEXT", "subtype": "PLAIN", "label": "Z" },
            { "id": "a", "order": 1, "type": "TEXT", "subtype": "PLAIN", "label": "A" },
            { "id": "m", "order": 2, "type": "TEXT", "subtype": "PLAIN", "label": "M" }
          ]
        }
        """
        let schema = try JSONDecoder().decode(FormSchema.self, from: Data(json.utf8))
        XCTAssertEqual(schema.renderableFieldsSortedByOrder.map(\.id), ["a", "m", "z"])
    }

    func testMissingFieldsArrayDoesNotCrash() throws {
        let json = """
        {
          "theme": { "background_color": "#FFF", "text_color": "#000", "border_color": "#CCC", "error_color": "#F00" },
          "form_title": "Empty"
        }
        """
        let schema = try JSONDecoder().decode(FormSchema.self, from: Data(json.utf8))
        XCTAssertTrue(schema.fields.isEmpty)
    }
}
