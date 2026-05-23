import XCTest
@testable import ServerDrivenUI

final class ValidationTests: XCTestCase {

    private func textField(id: String, required: Bool, maxLength: Int? = nil, regex: String? = nil) -> FormField {
        FormField(
            id: id, order: 0, label: id, required: required, errorMessage: nil,
            kind: .text(TextSpec(subtype: .plain, placeholder: nil, maxLength: maxLength, regex: regex, defaultValue: nil))
        )
    }

    func testRequiredFailsOnEmpty() {
        let field = textField(id: "n", required: true)
        let result = RequiredValidator().validate(value: .text(""), field: field)
        XCTAssertFalse(result.isValid)
    }

    func testRequiredPassesOnNonEmpty() {
        let field = textField(id: "n", required: true)
        let result = RequiredValidator().validate(value: .text("x"), field: field)
        XCTAssertTrue(result.isValid)
    }

    func testMaxLengthFailsAboveLimit() {
        let field = textField(id: "n", required: false, maxLength: 5)
        let result = MaxLengthValidator().validate(value: .text("123456"), field: field)
        XCTAssertFalse(result.isValid)
    }

    func testMaxLengthPassesAtLimit() {
        let field = textField(id: "n", required: false, maxLength: 5)
        let result = MaxLengthValidator().validate(value: .text("12345"), field: field)
        XCTAssertTrue(result.isValid)
    }

    func testRegexFailsOnNonMatch() {
        let field = textField(id: "u", required: false, regex: "^https?://.+")
        let result = RegexValidator().validate(value: .text("not-a-url"), field: field)
        XCTAssertFalse(result.isValid)
    }

    func testRegexPassesOnMatch() {
        let field = textField(id: "u", required: false, regex: "^https?://.+")
        let result = RegexValidator().validate(value: .text("https://example.com"), field: field)
        XCTAssertTrue(result.isValid)
    }

    func testRegexPassesOnEmpty() {
        let field = textField(id: "u", required: false, regex: "^https?://.+")
        let result = RegexValidator().validate(value: .text(""), field: field)
        XCTAssertTrue(result.isValid)
    }

    func testMultiSelectRequiredFailsWhenEmpty() {
        let field = FormField(
            id: "nw", order: 0, label: "Networks", required: true, errorMessage: nil,
            kind: .dropdown(DropdownSpec(options: [], allowMultiple: true, defaultValues: [], defaultValue: nil))
        )
        let result = RequiredValidator().validate(value: .multi([]), field: field)
        XCTAssertFalse(result.isValid)
    }

    func testDropdownAvailabilityFiresOnRequiredEmptyOptions() {
        let field = FormField(
            id: "ba", order: 0, label: "Billing Account", required: true, errorMessage: "Pick one",
            kind: .dropdown(DropdownSpec(options: [], allowMultiple: false, defaultValues: [], defaultValue: nil))
        )
        let result = DropdownAvailabilityValidator().validate(value: .single(nil), field: field)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Billing Account is unavailable right now. Please contact support.")
    }

    func testDropdownAvailabilityPassesWhenOptionsExist() {
        let field = FormField(
            id: "ba", order: 0, label: "Billing Account", required: true, errorMessage: nil,
            kind: .dropdown(DropdownSpec(
                options: [DropdownOption(id: "a", label: "A")],
                allowMultiple: false, defaultValues: [], defaultValue: nil))
        )
        let result = DropdownAvailabilityValidator().validate(value: .single(nil), field: field)
        XCTAssertTrue(result.isValid)
    }

    func testDropdownAvailabilityPassesWhenNotRequired() {
        let field = FormField(
            id: "ba", order: 0, label: "Billing Account", required: false, errorMessage: nil,
            kind: .dropdown(DropdownSpec(options: [], allowMultiple: false, defaultValues: [], defaultValue: nil))
        )
        let result = DropdownAvailabilityValidator().validate(value: .single(nil), field: field)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - URLFormatValidator

    private func uriField(id: String = "u", required: Bool = false, regex: String? = nil) -> FormField {
        FormField(
            id: id, order: 0, label: id, required: required, errorMessage: nil,
            kind: .text(TextSpec(subtype: .uri, placeholder: nil, maxLength: nil, regex: regex, defaultValue: nil))
        )
    }

    func testURLBaselinePassesOnValidHttps() {
        let result = URLFormatValidator().validate(value: .text("https://example.com"), field: uriField())
        XCTAssertTrue(result.isValid)
    }

    func testURLBaselinePassesOnAnyScheme() {
        // Baseline does not restrict the scheme — that's the server's job via regex.
        XCTAssertTrue(URLFormatValidator().validate(value: .text("ftp://server"), field: uriField()).isValid)
        XCTAssertTrue(URLFormatValidator().validate(value: .text("https://example.com/path?q=1"), field: uriField()).isValid)
    }

    func testURLBaselineFailsOnNonUrlText() {
        XCTAssertFalse(URLFormatValidator().validate(value: .text("not-a-url"), field: uriField()).isValid)
        XCTAssertFalse(URLFormatValidator().validate(value: .text("just words"), field: uriField()).isValid)
    }

    func testURLBaselineFailsOnSchemeWithoutHost() {
        XCTAssertFalse(URLFormatValidator().validate(value: .text("https://"), field: uriField()).isValid)
        XCTAssertFalse(URLFormatValidator().validate(value: .text("://example.com"), field: uriField()).isValid)
    }

    func testURLBaselinePassesEmpty() {
        // Empty is RequiredValidator's domain, not URL's.
        XCTAssertTrue(URLFormatValidator().validate(value: .text(""), field: uriField()).isValid)
        XCTAssertTrue(URLFormatValidator().validate(value: .text("   "), field: uriField(required: false)).isValid)
    }

    func testURLBaselineIgnoresNonUriSubtypes() {
        let plainField = FormField(
            id: "x", order: 0, label: "x", required: false, errorMessage: nil,
            kind: .text(TextSpec(subtype: .plain, placeholder: nil, maxLength: nil, regex: nil, defaultValue: nil))
        )
        XCTAssertTrue(URLFormatValidator().validate(value: .text("not-a-url"), field: plainField).isValid)
    }

    @MainActor
    func testViewModelStacksUrlBaselineAndJsonRegex() async {
        // Hybrid: server tightens to HTTPS-only via regex; baseline still rejects garbage.
        let schema = FormSchema(
            theme: .fallback, formTitle: "T",
            fields: [uriField(id: "u", required: true, regex: "^https://.+")]
        )
        let vm = FormViewModel(loader: MockFormLoader(schema: schema))
        await vm.load()

        // Garbage → URL baseline fires (not the regex).
        vm.setValue(.text("not-a-url"), for: schema.fields[0])
        XCTAssertNil(vm.validate())
        XCTAssertEqual(vm.error(for: schema.fields[0]),
                       "u must be a valid URL (e.g., https://example.com).")

        // Valid URL but wrong scheme → URL baseline passes, regex fires.
        vm.setValue(.text("http://example.com"), for: schema.fields[0])
        XCTAssertNil(vm.validate())
        XCTAssertEqual(vm.error(for: schema.fields[0]), "u format is invalid.")

        // Right scheme → both pass.
        vm.setValue(.text("https://example.com"), for: schema.fields[0])
        XCTAssertNotNil(vm.validate())
    }

    @MainActor
    func testViewModelEmitsMisconfigurationMessageForRequiredEmptyDropdown() async {
        let schema = FormSchema(
            theme: .fallback,
            formTitle: "Test",
            fields: [
                FormField(id: "ba", order: 1, label: "Billing Account",
                          required: true, errorMessage: "Pick one",
                          kind: .dropdown(DropdownSpec(options: [], allowMultiple: false,
                                                      defaultValues: [], defaultValue: nil)))
            ]
        )
        let vm = FormViewModel(loader: MockFormLoader(schema: schema))
        await vm.load()
        let payload = vm.validate()
        XCTAssertNil(payload, "Save should be blocked")
        XCTAssertEqual(vm.errors["ba"],
                       "Billing Account is unavailable right now. Please contact support.")
    }
}
