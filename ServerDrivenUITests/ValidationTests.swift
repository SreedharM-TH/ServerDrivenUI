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
