import Foundation
import Testing

@testable import notesToGo

extension ExplorerModuleTests {
    @MainActor
    struct ExplorerServiceTests {
        @Test
        func listingUsesRootAndSortsRepositoryResults() async throws {
            let repository = ExplorerRepositoryStub()
            let note = repository.note(named: "Alpha")
            let folder = repository.root.appendingPathComponent("Zulu")
            repository.documents = [.note(note), .folder(folder)]

            let documents = try await ExplorerService(repository: repository).loadAllDocs()

            #expect(documents == [.folder(folder), .note(note)])
            #expect(repository.listedFolder == repository.root)
        }

        @Test
        func creationValidatesBeforeTouchingRepository() async throws {
            let repository = ExplorerRepositoryStub()
            let service = ExplorerService(repository: repository)

            await #expect(throws: EditorError.invalidNoteName) {
                try await service.addNote(name: "../Escape")
            }
            #expect(throws: EditorError.invalidNoteName) {
                try service.addFolder(name: "../Escape")
            }
            #expect(repository.createdNote == nil)
            #expect(repository.createdFolder == nil)
            #expect(repository.ensuredFolders.isEmpty)

            let note = try await service.addNote(name: "  Trimmed  ")
            #expect(note == repository.note(named: "Trimmed"))
        }

        @Test
        func quickNoteNamingUsesRepositorySnapshotAndRequestedDestination() async throws {
            let repository = ExplorerRepositoryStub()
            let destination = repository.root.appendingPathComponent("Inbox")
            let date = Date(timeIntervalSince1970: 1_700_000_000)
            let base = DocumentNaming().quickNoteBaseName(date: date)
            repository.filenames = ["\(base).PDF", ".\(base) 2.markup"]

            let note = try await ExplorerService(repository: repository).addQuickNote(at: destination, date: date)

            #expect(repository.ensuredFolders == [destination])
            #expect(repository.filenamesFolder == destination)
            #expect(note.pdf == destination.appendingPathComponent("\(base) 3.pdf"))
        }

        @Test
        func folderCreationUsesUniqueNameAndInboxLivesUnderRoot() throws {
            let repository = ExplorerRepositoryStub()
            repository.filenames = ["Work", "Work 2"]
            let service = ExplorerService(repository: repository)

            let folder = try service.addFolder(name: "Work")
            let inbox = try service.inboxFolder()

            #expect(folder == repository.root.appendingPathComponent("Work 3", isDirectory: true))
            #expect(inbox == repository.root.appendingPathComponent("QuickNotes", isDirectory: true))
            #expect(repository.ensuredFolders == [repository.root, inbox])
        }

        @Test
        func repositoryErrorsPropagateWithoutCreatingAnything() async {
            let repository = ExplorerRepositoryStub()
            repository.failure = CocoaError(.fileReadNoPermission)
            let service = ExplorerService(repository: repository)

            await #expect(throws: CocoaError(.fileReadNoPermission)) {
                try await service.loadAllDocs()
            }
            await #expect(throws: CocoaError(.fileReadNoPermission)) {
                try await service.addQuickNote()
            }
            #expect(repository.createdNote == nil)
        }
    }
}

/// In-memory application-service seam: no FileManager, PDFKit, or subclassed service.
@MainActor
final class ExplorerRepositoryStub: ExplorerRepositoryProtocol {
    let root = URL(fileURLWithPath: "/ExplorerServiceTests", isDirectory: true)
    var documents: [Document] = []
    var filenames: [String] = []
    var failure: CocoaError?
    var listedFolder: URL?
    var filenamesFolder: URL?
    var ensuredFolders: [URL] = []
    var createdNote: Note?
    var createdFolder: URL?

    func rootFolder() -> URL { root }

    func loadDocuments(in folder: URL) throws -> [Document] {
        if let failure { throw failure }
        listedFolder = folder
        return documents
    }

    func filenames(in folder: URL) throws -> [String] {
        if let failure { throw failure }
        filenamesFolder = folder
        return filenames
    }

    func ensureFolderExists(_ folder: URL) throws {
        if let failure { throw failure }
        ensuredFolders.append(folder)
    }

    func createNote(at folder: URL, name: String) async throws -> Note {
        if let failure { throw failure }
        let note = Note(pdf: folder.appendingPathComponent("\(name).pdf"), markup: folder.appendingPathComponent(".\(name).markup"))
        createdNote = note
        return note
    }

    func createFolder(at folder: URL, name: String) throws -> URL {
        if let failure { throw failure }
        let result = folder.appendingPathComponent(name, isDirectory: true)
        createdFolder = result
        return result
    }

    func note(named name: String) -> Note {
        Note(pdf: root.appendingPathComponent("\(name).pdf"), markup: root.appendingPathComponent(".\(name).markup"))
    }
}
