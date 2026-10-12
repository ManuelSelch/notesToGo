#if DEBUG
import Foundation
import Testing
@testable import notesToGo

@MainActor
struct UITestStorageTests {
    @Test
    func isolatedRootsPreserveRelaunchDataAndCleanupOnlySelectedTest() throws {
        let fm = FileManager.default
        let base = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: base) }
        let first = try UITestStorage(environment: ["NOTESTOGO_UI_TEST_ID": UUID().uuidString], temporaryDirectory: base)
        let second = try UITestStorage(environment: ["NOTESTOGO_UI_TEST_ID": UUID().uuidString], temporaryDirectory: base)
        try first.prepare()
        try second.prepare()
        let file = try #require(first.root).appendingPathComponent("note.pdf")
        try Data("retained".utf8).write(to: file)
        try first.prepare()
        #expect(try Data(contentsOf: file) == Data("retained".utf8))
        #expect(first.root != second.root)
        try first.cleanup()
        #expect(!fm.fileExists(atPath: try #require(first.root).path))
        #expect(fm.fileExists(atPath: try #require(second.root).path))
        try first.cleanup() // Idempotent cleanup.
    }

    @Test
    func normalLaunchDoesNotCreateOrRemoveStorage() throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let storage = try UITestStorage(environment: [:], temporaryDirectory: base)
        #expect(storage.root == nil)
        try storage.prepare()
        try storage.cleanup()
        #expect(!FileManager.default.fileExists(atPath: base.path))
    }

    @Test(arguments: ["", "../Documents", "/tmp", "not-a-uuid"])
    func invalidIDsAreRejected(id: String) {
        #expect(throws: (any Error).self) {
            try UITestStorage(environment: ["NOTESTOGO_UI_TEST_ID": id])
        }
    }
}
#endif
