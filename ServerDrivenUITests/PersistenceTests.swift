import XCTest
@testable import ServerDrivenUI

final class PersistenceTests: XCTestCase {

    // MARK: - FieldValue Codable

    func testFieldValueCodableRoundTripText() throws {
        try assertRoundTrip(.text("Summer Sale"))
    }

    func testFieldValueCodableRoundTripBool() throws {
        try assertRoundTrip(.bool(true))
        try assertRoundTrip(.bool(false))
    }

    func testFieldValueCodableRoundTripSingleNil() throws {
        try assertRoundTrip(.single(nil))
    }

    func testFieldValueCodableRoundTripSingleValue() throws {
        try assertRoundTrip(.single("net_meta"))
    }

    func testFieldValueCodableRoundTripMulti() throws {
        try assertRoundTrip(.multi(["a", "b", "c"]))
    }

    private func assertRoundTrip(_ value: FieldValue, file: StaticString = #filePath, line: UInt = #line) throws {
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(FieldValue.self, from: data)
        XCTAssertEqual(decoded, value, file: file, line: line)
    }

    // MARK: - Core Data round-trip

    func testCoreDataPersistenceRoundTrip() async throws {
        let stack = CoreDataStack(inMemory: true)
        let persistence = CoreDataFormStatePersistence(stack: stack)

        let payload: [String: FieldValue] = [
            "campaign_name": .text("Black Friday"),
            "ad_networks": .multi(["net_meta", "net_google"]),
            "enable_ai_opt": .bool(true),
            "billing_account": .single(nil)
        ]
        try await persistence.save(payload)

        let loaded = try await persistence.load()
        XCTAssertEqual(loaded, payload)
    }

    func testCoreDataPersistenceUpsertReplacesExistingRow() async throws {
        let stack = CoreDataStack(inMemory: true)
        let persistence = CoreDataFormStatePersistence(stack: stack)

        try await persistence.save(["campaign_name": .text("v1")])
        try await persistence.save(["campaign_name": .text("v2")])
        let loaded = try await persistence.load()
        XCTAssertEqual(loaded["campaign_name"], .text("v2"))
    }

    func testCoreDataPersistenceGCsRemovedFields() async throws {
        let stack = CoreDataStack(inMemory: true)
        let persistence = CoreDataFormStatePersistence(stack: stack)

        try await persistence.save(["a": .text("1"), "b": .text("2")])
        try await persistence.save(["a": .text("1")])
        let loaded = try await persistence.load()
        XCTAssertEqual(loaded.keys.sorted(), ["a"])
    }

    func testCoreDataPersistenceClearRemovesEverything() async throws {
        let stack = CoreDataStack(inMemory: true)
        let persistence = CoreDataFormStatePersistence(stack: stack)

        try await persistence.save(["a": .text("1"), "b": .bool(true)])
        try await persistence.clear()
        let loaded = try await persistence.load()
        XCTAssertTrue(loaded.isEmpty)
    }

    // MARK: - ViewModel draft semantics

    private func makeSchema(maxLength: Int? = nil, defaultValue: String? = nil, required: Bool = false) -> FormSchema {
        FormSchema(
            theme: .fallback,
            formTitle: "T",
            fields: [
                FormField(id: "name", order: 1, label: "Name", required: required, errorMessage: nil,
                          kind: .text(TextSpec(subtype: .plain, placeholder: nil, maxLength: maxLength,
                                               regex: nil, defaultValue: defaultValue)))
            ]
        )
    }

    @MainActor
    func testViewModelHydratesFromDraftOverridingDefaults() async throws {
        let schema = makeSchema(defaultValue: "Default")
        let persistence = InMemoryFormStatePersistence(seed: ["name": .text("Persisted")])
        let vm = FormViewModel(loader: MockFormLoader(schema: schema), persistence: persistence)
        await vm.load()
        if case .text(let s) = vm.value(for: schema.fields[0]) {
            XCTAssertEqual(s, "Persisted")
        } else {
            XCTFail("Expected text value")
        }
    }

    @MainActor
    func testViewModelPersistsOnEditAfterDebounce() async throws {
        let schema = makeSchema()
        let persistence = InMemoryFormStatePersistence()
        let vm = FormViewModel(loader: MockFormLoader(schema: schema),
                               persistence: persistence,
                               persistDebounce: .milliseconds(20))
        await vm.load()
        vm.setValue(.text("Drafting"), for: schema.fields[0])

        try await Task.sleep(nanoseconds: 100_000_000)

        let loaded = try await persistence.load()
        XCTAssertEqual(loaded["name"], .text("Drafting"))
    }

    @MainActor
    func testViewModelDebounceCoalescesBurstEdits() async throws {
        let schema = makeSchema()
        let persistence = InMemoryFormStatePersistence()
        let vm = FormViewModel(loader: MockFormLoader(schema: schema),
                               persistence: persistence,
                               persistDebounce: .milliseconds(50))
        await vm.load()

        // Three quick edits — only the last value should land after debounce.
        vm.setValue(.text("a"), for: schema.fields[0])
        vm.setValue(.text("ab"), for: schema.fields[0])
        vm.setValue(.text("abc"), for: schema.fields[0])

        try await Task.sleep(nanoseconds: 200_000_000)

        let loaded = try await persistence.load()
        XCTAssertEqual(loaded["name"], .text("abc"))
    }

    @MainActor
    func testViewModelClearsDraftOnSuccessfulSave() async throws {
        let schema = makeSchema(required: true)
        let persistence = InMemoryFormStatePersistence(seed: ["name": .text("Drafting")])
        let vm = FormViewModel(loader: MockFormLoader(schema: schema),
                               persistence: persistence,
                               persistDebounce: .milliseconds(20))
        await vm.load()
        vm.setValue(.text("Final"), for: schema.fields[0])

        XCTAssertNotNil(vm.validate())
        try await Task.sleep(nanoseconds: 100_000_000)

        let loaded = try await persistence.load()
        XCTAssertTrue(loaded.isEmpty, "Draft should be cleared after successful Save")
    }

    @MainActor
    func testViewModelKeepsDraftOnFailedValidation() async throws {
        let schema = makeSchema(required: true)
        let persistence = InMemoryFormStatePersistence()
        let vm = FormViewModel(loader: MockFormLoader(schema: schema),
                               persistence: persistence,
                               persistDebounce: .milliseconds(20))
        await vm.load()
        vm.setValue(.text("Mid-draft"), for: schema.fields[0])
        try await Task.sleep(nanoseconds: 100_000_000)

        // Now blank it out and try to save — validation fails (required).
        vm.setValue(.text(""), for: schema.fields[0])
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNil(vm.validate())
        try await Task.sleep(nanoseconds: 100_000_000)

        let loaded = try await persistence.load()
        // The last persisted snapshot (empty string) is still there — what matters
        // is that clear() did NOT run on the failed save.
        XCTAssertEqual(loaded["name"], .text(""))
    }

    @MainActor
    func testViewModelNormalizesDraftToCurrentMaxLength() async throws {
        let schema = makeSchema(maxLength: 5)
        let persistence = InMemoryFormStatePersistence(seed: ["name": .text("abcdefghij")])
        let vm = FormViewModel(loader: MockFormLoader(schema: schema), persistence: persistence)
        await vm.load()
        if case .text(let s) = vm.value(for: schema.fields[0]) {
            XCTAssertEqual(s, "abcde")
        } else {
            XCTFail("Expected text value")
        }
    }
}
