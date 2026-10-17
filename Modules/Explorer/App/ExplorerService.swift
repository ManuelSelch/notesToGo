import Foundation

/// Coordinates explorer use cases; storage and PDF details stay behind the repository.
final class ExplorerService {
    private let repository: any ExplorerRepositoryProtocol
    private let naming: DocumentNaming
    private let ordering: DocumentOrdering

    init(
        repository: any ExplorerRepositoryProtocol,
        naming: DocumentNaming = DocumentNaming(),
        ordering: DocumentOrdering = DocumentOrdering()
    ) {
        self.repository = repository
        self.naming = naming
        self.ordering = ordering
    }

    func loadAllDocs(in folder: URL? = nil) async throws -> [Document] {
        ordering.sorted(try repository.loadDocuments(in: folder ?? repository.rootFolder()))
    }

    func addNote(at folder: URL? = nil, name: String) async throws -> Note {
        let name = try NoteName.validated(name)
        return try await repository.createNote(at: folder ?? repository.rootFolder(), name: name)
    }

    func addQuickNote(at folder: URL? = nil, date: Date = .now) async throws -> Note {
        let folder = folder ?? repository.rootFolder()
        try repository.ensureFolderExists(folder)
        let name = naming.uniqueNoteName(
            base: naming.quickNoteBaseName(date: date),
            filenames: try repository.filenames(in: folder)
        )
        return try await addNote(at: folder, name: name)
    }

    func inboxFolder() throws -> URL {
        let folder = repository.rootFolder().appendingPathComponent("QuickNotes", isDirectory: true)
        try repository.ensureFolderExists(folder)
        return folder
    }

    func addFolder(at folder: URL? = nil, name: String) throws -> URL {
        let name = try NoteName.validated(name)
        let parent = folder ?? repository.rootFolder()
        try repository.ensureFolderExists(parent)
        let uniqueName = naming.uniqueFolderName(base: name, filenames: try repository.filenames(in: parent))
        return try repository.createFolder(at: parent, name: uniqueName)
    }
}
