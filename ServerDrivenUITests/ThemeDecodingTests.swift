import XCTest
import SwiftUI
@testable import ServerDrivenUI

final class ThemeDecodingTests: XCTestCase {

    func testHexColorParsing() {
        XCTAssertNotNil(Color(hex: "#FFFFFF"))
        XCTAssertNotNil(Color(hex: "121212"))
        XCTAssertNotNil(Color(hex: "#BB86FC"))
        XCTAssertNotNil(Color(hex: "#BB86FCFF"))
        XCTAssertNil(Color(hex: "not-a-color"))
        XCTAssertNil(Color(hex: "#ZZZZZZ"))
        XCTAssertNil(Color(hex: ""))
    }

    func testThemeDecodes() throws {
        let json = """
        { "background_color": "#121212", "text_color": "#E0E0E0", "border_color": "#333", "error_color": "#CF6679" }
        """
        let theme = try JSONDecoder().decode(Theme.self, from: Data(json.utf8))
        XCTAssertEqual(theme.backgroundColor, "#121212")
        XCTAssertEqual(theme.errorColor, "#CF6679")
    }

    func testMissingThemeKeysFallbackToDefault() throws {
        let json = """
        { "background_color": "#000" }
        """
        let theme = try JSONDecoder().decode(Theme.self, from: Data(json.utf8))
        XCTAssertEqual(theme.backgroundColor, "#000")
        XCTAssertEqual(theme.textColor, Theme.fallback.textColor)
    }
}
