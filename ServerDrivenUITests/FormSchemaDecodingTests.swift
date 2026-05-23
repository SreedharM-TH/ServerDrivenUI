import XCTest
@testable import ServerDrivenUI

final class FormSchemaDecodingTests: XCTestCase {

    /// Smoke test against the assignment's "all-in-one" payload — covers
    /// out-of-order fields, empty options, unknown type, default exceeding max_length,
    /// metadata-with-links checkbox, secure/uri text fields, and a toggle.
    private let allInOneJSON = """
    {
      "theme": {
        "background_color": "#121212",
        "text_color": "#E0E0E0",
        "border_color": "#333333",
        "error_color": "#CF6679"
      },
      "form_title": "Comprehensive Campaign Setup",
      "fields": [
        { "id": "ad_networks", "order": 4, "type": "DROPDOWN", "label": "Ad Networks",
          "allow_multiple": true, "required": true,
          "options": [
            { "id": "net_google", "label": "Google Search" },
            { "id": "net_meta", "label": "Meta Platforms" },
            { "id": "net_tiktok", "label": "TikTok" }
          ]
        },
        { "id": "accept_legal", "order": 2, "type": "CHECKBOX",
          "label": "I agree to the Terms of Service and Privacy Policy.",
          "required": true,
          "metadata": {
            "Terms of Service": "https://example.com/terms",
            "Privacy Policy": "https://example.com/privacy"
          },
          "clickable_text_color": "#BB86FC"
        },
        { "id": "campaign_name", "order": 1, "type": "TEXT", "subtype": "PLAIN",
          "label": "Campaign Name",
          "default_value": "Summer Sale 2026 - Extended Promotional Edition",
          "max_length": 20, "required": true
        },
        { "id": "brand_color", "order": 6, "type": "COLOR_PICKER", "label": "Primary Brand Color" },
        { "id": "enable_ai_opt", "order": 8, "type": "TOGGLE", "label": "Enable AI",
          "default_value": true
        },
        { "id": "billing_account", "order": 5, "type": "DROPDOWN", "label": "Billing Account",
          "required": true, "options": []
        },
        { "id": "admin_password", "order": 9, "type": "TEXT", "subtype": "SECURE",
          "label": "Admin Password", "required": true
        },
        { "id": "destination_url", "order": 3, "type": "TEXT", "subtype": "URI",
          "label": "Destination URL", "placeholder": "https://", "required": true
        }
      ]
    }
    """

    func testAllInOnePayloadDecodes() throws {
        let schema = try JSONDecoder().decode(FormSchema.self, from: Data(allInOneJSON.utf8))
        XCTAssertEqual(schema.fields.count, 8)
    }

    func testRenderableOmitsUnsupportedAndSortsByOrder() throws {
        let schema = try JSONDecoder().decode(FormSchema.self, from: Data(allInOneJSON.utf8))
        let visible = schema.renderableFieldsSortedByOrder
        XCTAssertEqual(visible.map(\.id),
                       ["campaign_name", "accept_legal", "destination_url", "ad_networks",
                        "billing_account", "enable_ai_opt", "admin_password"])
    }

    func testCheckboxMetadataPreserved() throws {
        let schema = try JSONDecoder().decode(FormSchema.self, from: Data(allInOneJSON.utf8))
        let legal = schema.fields.first { $0.id == "accept_legal" }
        XCTAssertNotNil(legal)
        guard case .checkbox(let spec) = legal!.kind else { return XCTFail("Expected checkbox kind") }
        XCTAssertEqual(spec.metadata.count, 2)
        XCTAssertEqual(spec.clickableTextColor, "#BB86FC")
    }

    func testTextDefaultExceedingMaxLengthPreservedInModel() throws {
        // The model preserves the raw default; truncation is a view-model concern.
        let schema = try JSONDecoder().decode(FormSchema.self, from: Data(allInOneJSON.utf8))
        let name = schema.fields.first { $0.id == "campaign_name" }
        XCTAssertNotNil(name)
        guard case .text(let spec) = name!.kind else { return XCTFail("Expected text kind") }
        XCTAssertEqual(spec.maxLength, 20)
        XCTAssertEqual(spec.defaultValue, "Summer Sale 2026 - Extended Promotional Edition")
    }

    @MainActor
    func testViewModelTruncatesDefaultToMaxLength() async throws {
        let schema = try JSONDecoder().decode(FormSchema.self, from: Data(allInOneJSON.utf8))
        let vm = FormViewModel(loader: MockFormLoader(schema: schema))
        await vm.load()
        let nameField = schema.fields.first { $0.id == "campaign_name" }!
        let value = vm.value(for: nameField)
        if case .text(let s) = value {
            XCTAssertLessThanOrEqual(s.count, 20)
        } else {
            XCTFail("Expected text value")
        }
    }
}
