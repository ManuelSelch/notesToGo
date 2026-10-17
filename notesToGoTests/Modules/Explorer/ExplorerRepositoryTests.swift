import Foundation
import Testing

@testable import notesToGo

@MainActor
struct ExplorerRepositoryTests {
    @Test
    func listingPreservesActualPDFURLsAndHidesStagingFolders() async throws {
        let root = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let pdf = root.appendingPathComponent("Imported.PdF")
        try Data().write(to: pdf)
        try Data().write(to: root.appendingPathComponent(".Imported.markup"))
        try Data().write(to: root.appendingPathComponent("Other.txt"))
        let folder = root.appendingPathComponent("Visible", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
        try FileManager.default.createDirectory(at: root.appendingPathComponent(".notestogo-create-leftover"), withIntermediateDirectories: false)
        let repository = ExplorerRepository(root: root)

        let documents = try repository.loadDocuments(in: root)
        let expectedNote = Note(pdf: pdf, markup: root.appendingPathComponent(".Imported.markup"))

        #expect(repository.rootFolder() == root)
        #expect(Set(documents) == Set([.note(expectedNote), .folder(folder)]))
        #expect(try repository.filenames(in: root).contains(".Imported.markup"))
        #expect(try await ExplorerService(repository: repository).loadAllDocs() == [.folder(folder), .note(expectedNote)])
    }

    @Test
    func folderCreationReservesBothFilesAndDirectories() throws {
        let root = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        try Data("Keep".utf8).write(to: root.appendingPathComponent("Work"))
        let service = ExplorerService(repository: ExplorerRepository(root: root))

        let first = try service.addFolder(name: "Work")
        let second = try service.addFolder(name: "Work")

        #expect(first.lastPathComponent == "Work 2")
        #expect(second.lastPathComponent == "Work 3")
        #expect(try Data(contentsOf: root.appendingPathComponent("Work")) == Data("Keep".utf8))
    }

    @Test
    func repositoryRejectsInvalidNamesBeforeCreatingAnyDirectories() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let repository = ExplorerRepository(root: root)

        await #expect(throws: EditorError.invalidNoteName) {
            try await repository.createNote(at: root, name: "../Escape")
        }
        #expect(throws: EditorError.invalidNoteName) {
            try repository.createFolder(at: root, name: "../Escape")
        }
        #expect(!FileManager.default.fileExists(atPath: root.path))
    }

    private func temporaryFolder() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
        return root
    }
}
