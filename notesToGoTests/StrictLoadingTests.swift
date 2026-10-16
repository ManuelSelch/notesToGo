import Foundation
import PDFKit
import Testing

@testable import notesToGo

@Suite
@MainActor
struct StrictLoadingTests {
    @Test
    func validSidecarDoesNotHideMissingPDF() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let note = try await Explorer().addNote(at: folder, name: "Missing PDF")
        try FileManager.default.removeItem(at: note.pdf)

        await #expect(throws: EditorError.documentNotFound) {
            try await DocumentRepository().load(note)
        }
        #expect(FileManager.default.fileExists(atPath: note.markup.path))
    }

    @Test
    func validSidecarDoesNotHideDamagedPDF() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let note = try await Explorer().addNote(at: folder, name: "Damaged PDF")
        let source = try Data(contentsOf: note.markup)
        try Data("Not a PDF".utf8).write(to: note.pdf)

        await #expect(throws: EditorError.invalidPDF) {
            try await DocumentRepository().load(note)
        }
        #expect(try Data(contentsOf: note.markup) == source)
    }

    @Test
    func missingFolderIsNotAnEmptyListing() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        await #expect(throws: (any Error).self) {
            try await Explorer().loadAllDocs(in: folder)
        }
    }

    @Test
    func openingAnotherNoteClearsPreviousDocument() {
        var state = EditorFeature.State()
        state.document = .empty
        let note = Note(pdf: URL(fileURLWithPath: "/Missing.pdf"), markup: URL(fileURLWithPath: "/.Missing.markup"))

        EditorFeature().reduce(&state, .openNote(note))

        #expect(state.document == nil)
        #expect(state.isLoading)
    }

    @Test
    func savingWithoutLoadedDocumentDoesNotStartAnOperation() {
        var state = EditorFeature.State()

        EditorFeature().reduce(&state, .save([:]))

        #expect(!state.isLoading)
        #expect(state.document == nil)
    }

    @Test
    func pageRequestsAreIgnoredUntilDocumentLoads() async {
        let result = await PageMiddleware().handle(state: .init(), action: .addPageTapped)

        #expect(result == nil)
    }

    @Test(arguments: ["Not JSON", "{\"formatVersion\":1,\"document\":{\"pages\":\"broken\"}}", "{\"formatVersion\":1,\"document\":{\"pages\":[{\"id\":\"not-a-uuid\"}]}}"])
    func corruptSidecarsAreReportedAndNeverReplaced(content: String) async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let note = try await Explorer().addNote(at: folder, name: "Corrupt")
        let original = Data(content.utf8)
        try original.write(to: note.markup)

        await #expect(throws: EditorError.corruptDocument) {
            try await DocumentRepository().load(note)
        }
        #expect(try Data(contentsOf: note.markup) == original)
    }

    @Test
    func unreadableSidecarDoesNotFallBackToPDFOnlyDocument() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let note = try await Explorer().addNote(at: folder, name: "Unreadable")
        try FileManager.default.removeItem(at: note.markup)
        try FileManager.default.createDirectory(at: note.markup, withIntermediateDirectories: false)

        await #expect(throws: (any Error).self) {
            try await DocumentRepository().load(note)
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: note.markup.path).isEmpty)
    }

    private func temporaryFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}
