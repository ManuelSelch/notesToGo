#if DEBUG
import FactoryKit
import Foundation
import PDFKit

/// Debug-only real-file fixtures requested explicitly by error-flow UI tests.
/// Normal launches and Release builds never create these files.
enum UITestFixtures {
    /// Register before creating the editor store: @Injected captures its services eagerly.
    static func registerEditorRepository(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws {
        let storage = try UITestStorage(environment: environment)
        guard storage.root != nil, !storage.isCleanup,
              let mode = environment["NOTESTOGO_UI_TEST_SAVE_MODE"],
              ["delayed", "failOnce"].contains(mode) else { return }
        Container.shared.documentRepository.register {
            UITestSaveRepository(failFirstSave: mode == "failOnce")
        }
    }

    static func prepare() throws {
        let environment = ProcessInfo.processInfo.environment
        guard try UITestStorage().root != nil,
              let requestedName = environment["NOTESTOGO_UI_TEST_NOTE"],
              requestedName.hasPrefix("AT Error "),
              let format = environment["NOTESTOGO_UI_TEST_MARKUP"],
              ["corrupt", "unsupported"].contains(format) else { return }
        let name = try NoteName.validated(requestedName)
        let folder = Explorer().rootFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let pdfURL = folder.appendingPathComponent("\(name).pdf")
        let markupURL = folder.appendingPathComponent(".\(name).markup")
        guard !FileManager.default.fileExists(atPath: pdfURL.path),
              !FileManager.default.fileExists(atPath: markupURL.path) else { return }
        let pdf = PDFDocument()
        pdf.insert(PDFPage(), at: 0)
        guard pdf.write(to: pdfURL) else { throw EditorError.pdfWriteFailed }
        let content = format == "corrupt" ? "Damaged editable note data" : "{\"formatVersion\":999}"
        try Data(content.utf8).write(to: markupURL, options: .atomic)
    }
}

/// Real storage underneath; only timing and the first write failure are injected.
private final class UITestSaveRepository: DocumentRepositoryProtocol {
    private let repository = DocumentRepository()
    private var failFirstSave: Bool

    init(failFirstSave: Bool) { self.failFirstSave = failFirstSave }

    func save(_ document: MultiPageDocument, at path: URL) async throws {
        try await Task.sleep(for: .seconds(3))
        if failFirstSave {
            failFirstSave = false
            throw CocoaError(.fileWriteNoPermission)
        }
        try await repository.save(document, at: path)
    }

    func load(_ note: Note) async throws -> MultiPageDocument {
        try await repository.load(note)
    }
}
#endif
