import Foundation
import PDFKit
import PaperKit
import Testing

@testable import notesToGo

@Suite
@MainActor
struct DocumentStorageTests {
    @Test
    func createdNoteReopensBeforeFirstEditorSave() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }

        let note = try await ExplorerService(repository: ExplorerRepository()).addNote(at: folder, name: "New Note")
        let document = try await DocumentRepository().load(note)

        #expect(document.pages.count == 1)
        let page = try #require(document.pages.first)
        let pdf = try #require(PDFDocument(url: note.pdf))
        #expect(pdf.pageCount == 1)
        #expect(pdf.page(at: 0)?.bounds(for: .mediaBox) == page.markup.bounds)
        #expect(page.background == Page.empty.background)
    }

    @Test
    func savedDocumentHasExplicitFormatVersion() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let path = folder.appendingPathComponent(".Versioned.markup")

        try await DocumentRepository().save(.empty, at: path)
        let json = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: path)) as? [String: Any])

        #expect(json["formatVersion"] as? Int == 1)
    }

    @Test(arguments: ["", "   ", ".", "..", "../Outside", "Folder/Note", "Folder\\Note", "Bad\u{0000}Name"])
    func invalidNamesDoNotCreateFiles(name: String) async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }

        await #expect(throws: (any Error).self) {
            try await ExplorerService(repository: ExplorerRepository()).addNote(at: folder, name: name)
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).isEmpty)
    }

    @Test(arguments: ["Existing.pdf", ".Existing.markup", "Existing.PDF"])
    func creatingNoteNeverOverwritesEitherFile(filename: String) async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let existing = folder.appendingPathComponent(filename)
        let original = Data("Existing user data".utf8)
        try original.write(to: existing)

        await #expect(throws: (any Error).self) {
            try await ExplorerService(repository: ExplorerRepository()).addNote(at: folder, name: "Existing")
        }
        #expect(try Data(contentsOf: existing) == original)
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path) == [filename])
    }

    @Test
    func savedMultipageDocumentPreservesContentsAndMetadata() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let note = Note(pdf: folder.appendingPathComponent("Pages.pdf"), markup: folder.appendingPathComponent(".Pages.markup"))
        var first = Page.empty
        first.markup.insertNewTextbox(attributedText: NSAttributedString(string: "Keep my note"), frame: CGRect(x: 20, y: 30, width: 180, height: 40))
        let second = Page(bounds: CGRect(x: 0, y: 0, width: 420, height: 594), background: .plain(.white))
        let original = MultiPageDocument(pages: [first, second])
        let repository = DocumentRepository()

        let pdf = PDFDocument()
        pdf.insert(PDFPage(), at: 0)
        try #require(pdf.write(to: note.pdf))
        try await repository.save(original, at: note.markup)
        let loaded = try await repository.load(note)

        #expect(loaded.pages.map(\.id) == original.pages.map(\.id))
        #expect(loaded.pages.map(\.background) == original.pages.map(\.background))
        #expect(loaded.pages.map { $0.markup.bounds } == original.pages.map { $0.markup.bounds })
        #expect(loaded.pages.map(\.markup) == original.pages.map(\.markup))
    }

    @Test(arguments: ["Source.PDF", "Source.PdF"])
    func pdfOnlyNoteUsesActualURL(filename: String) async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let note = Note(pdf: folder.appendingPathComponent(filename), markup: folder.appendingPathComponent(".DifferentName.markup"))
        let pdf = PDFDocument()
        let first = PDFPage()
        first.setBounds(CGRect(x: 0, y: 0, width: 420, height: 594), for: .mediaBox)
        let second = PDFPage()
        second.setBounds(CGRect(x: 0, y: 0, width: 300, height: 500), for: .mediaBox)
        pdf.insert(first, at: 0)
        pdf.insert(second, at: 1)
        try #require(pdf.write(to: note.pdf))

        let loaded = try await DocumentRepository().load(note)

        #expect(loaded.pages.count == 2)
        #expect(loaded.pages.map { $0.markup.bounds } == [first.bounds(for: .mediaBox), second.bounds(for: .mediaBox)])
        #expect(!FileManager.default.fileExists(atPath: note.markup.path))
    }

    @Test(arguments: [0, 2, 999])
    func unsupportedVersionIsRejectedBeforeDocumentDecoding(version: Int) async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let note = Note(pdf: folder.appendingPathComponent("Version.pdf"), markup: folder.appendingPathComponent(".Version.markup"))
        let data = Data("{\"formatVersion\":\(version)}".utf8)
        try data.write(to: note.markup)

        await #expect(throws: EditorError.unsupportedFormatVersion(version)) {
            try await DocumentRepository().load(note)
        }
        #expect(try Data(contentsOf: note.markup) == data)
    }

    @Test
    func unversionedJSONIsRejectedWithoutChangingIt() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let note = Note(pdf: folder.appendingPathComponent("Old.pdf"), markup: folder.appendingPathComponent(".Old.markup"))
        let data = Data("{\"pages\":[]}".utf8)
        try data.write(to: note.markup)

        await #expect(throws: EditorError.missingFormatVersion) {
            try await DocumentRepository().load(note)
        }
        #expect(try Data(contentsOf: note.markup) == data)
    }

    @Test
    func rawPaperKitIsRejectedWithoutChangingIt() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let note = Note(pdf: folder.appendingPathComponent("Old.pdf"), markup: folder.appendingPathComponent(".Old.markup"))
        let data = try await Page.empty.markup.dataRepresentation()
        try data.write(to: note.markup)

        await #expect(throws: (any Error).self) {
            try await DocumentRepository().load(note)
        }
        #expect(try Data(contentsOf: note.markup) == data)
    }

    @Test
    func quickNotesUseCanonicalFormatAndUniqueNames() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let explorer = ExplorerService(repository: ExplorerRepository())
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let first = try await explorer.addQuickNote(at: folder, date: date)
        let second = try await explorer.addQuickNote(at: folder, date: date)

        #expect(first.pdf != second.pdf)
        #expect(second.pdf.deletingPathExtension().lastPathComponent == first.pdf.deletingPathExtension().lastPathComponent + " 2")
        #expect(try await DocumentRepository().load(first).pages.count == 1)
        #expect(try await DocumentRepository().load(second).pages.count == 1)
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).count == 4)
    }

    @Test
    func pdfWriteFailureLeavesNoPartialNote() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let generator = BlankPDFGenerator(writePDF: { _, path in
            try? Data("Partial PDF".utf8).write(to: path)
            return false
        })
        let explorer = ExplorerService(repository: ExplorerRepository(pdfGenerator: generator))

        await #expect(throws: EditorError.pdfWriteFailed) {
            try await explorer.addNote(at: folder, name: "Failed")
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).isEmpty)
    }

    @Test
    func sidecarWriteFailureLeavesNoPartialNote() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let explorer = ExplorerService(repository: ExplorerRepository(documentRepository: FailingDocumentRepository()))

        await #expect(throws: CocoaError(.fileWriteUnknown)) {
            try await explorer.addNote(at: folder, name: "Failed")
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).isEmpty)
    }

    @Test(arguments: ["markup", "pdf"])
    func publishFailureRollsBackTheNotePair(extensionToFail: String) async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let repository = ExplorerRepository(publishFile: { source, destination in
            if destination.pathExtension == extensionToFail { throw CocoaError(.fileWriteUnknown) }
            try FileManager.default.moveItem(at: source, to: destination)
        })
        let explorer = ExplorerService(repository: repository)

        await #expect(throws: CocoaError(.fileWriteUnknown)) {
            try await explorer.addNote(at: folder, name: "Failed")
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).isEmpty)
    }

    @Test(arguments: ["markup", "pdf"])
    func collisionDuringPublishingDoesNotOverwriteOtherFiles(extensionToCollide: String) async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let original = Data("Created by another operation".utf8)
        let repository = ExplorerRepository(publishFile: { source, destination in
            if destination.pathExtension == extensionToCollide { try original.write(to: destination) }
            try FileManager.default.moveItem(at: source, to: destination)
        })
        let explorer = ExplorerService(repository: repository)

        await #expect(throws: (any Error).self) {
            try await explorer.addNote(at: folder, name: "Collision")
        }
        let filename = extensionToCollide == "pdf" ? "Collision.pdf" : ".Collision.markup"
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path) == [filename])
        #expect(try Data(contentsOf: folder.appendingPathComponent(filename)) == original)
    }

    @Test
    func failedSerializationPreservesLastSavedDocument() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let note = try await ExplorerService(repository: ExplorerRepository()).addNote(at: folder, name: "Saved")
        let original = try Data(contentsOf: note.markup)
        var invalid = MultiPageDocument.empty
        invalid.pages[0].background = .lined(lineColor: .black, backgroundColor: .white, spacing: .infinity, lineWidth: 1)

        await #expect(throws: (any Error).self) {
            try await DocumentRepository().save(invalid, at: note.markup)
        }
        #expect(try Data(contentsOf: note.markup) == original)
        #expect(try await DocumentRepository().load(note).pages.count == 1)
    }

    private func temporaryFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}

@MainActor
private final class FailingDocumentRepository: DocumentRepositoryProtocol {
    func save(_ document: MultiPageDocument, at path: URL) async throws {
        try Data("Partial sidecar".utf8).write(to: path)
        throw CocoaError(.fileWriteUnknown)
    }

    func load(_ note: Note) async throws -> MultiPageDocument {
        throw EditorError.documentNotFound
    }
}
