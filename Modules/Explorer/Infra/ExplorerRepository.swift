import Foundation

/// Filesystem adapter. Publication and rollback of a note pair form one storage operation.
final class ExplorerRepository: ExplorerRepositoryProtocol {
    private let fm: FileManager
    private let documentRepository: any DocumentRepositoryProtocol
    private let pdfGenerator: BlankPDFGenerator
    private let publishFile: (URL, URL) throws -> Void
    private let root: URL?

    init(
        documentRepository: any DocumentRepositoryProtocol = DocumentRepository(),
        fileManager: FileManager = .default,
        pdfGenerator: BlankPDFGenerator = BlankPDFGenerator(),
        root: URL? = nil,
        publishFile: ((URL, URL) throws -> Void)? = nil
    ) {
        self.documentRepository = documentRepository
        fm = fileManager
        self.pdfGenerator = pdfGenerator
        self.root = root
        self.publishFile = publishFile ?? { try fileManager.moveItem(at: $0, to: $1) }
    }

    func rootFolder() -> URL {
        if let root { return root }
        #if DEBUG
        do {
            if let root = try UITestStorage().root { return root }
        } catch {
            fatalError("Invalid UI-test storage configuration: \(error)")
        }
        #endif
        return fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func loadDocuments(in folder: URL) throws -> [Document] {
        let files = try fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        let notes = files
            .filter { $0.pathExtension.lowercased() == "pdf" }
            .map { Document.note(noteURLs(pdf: $0)) }
        let visibleEntries = try fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        let folders = visibleEntries.filter { url in
            var isDirectory: ObjCBool = false
            return fm.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
        }
        return notes + folders.map { .folder($0) }
    }

    func filenames(in folder: URL) throws -> [String] {
        try fm.contentsOfDirectory(atPath: folder.path)
    }

    func ensureFolderExists(_ folder: URL) throws {
        if !fm.fileExists(atPath: folder.path) {
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }
    }

    func createFolder(at folder: URL, name: String) throws -> URL {
        let name = try NoteName.validated(name)
        let destination = folder.appendingPathComponent(name, isDirectory: true)
        try fm.createDirectory(at: destination, withIntermediateDirectories: false)
        return destination
    }

    func createNote(at folder: URL, name: String) async throws -> Note {
        let name = try NoteName.validated(name)
        try ensureFolderExists(folder)
        guard try !DocumentNaming().noteNameExists(name, filenames: filenames(in: folder)) else {
            throw EditorError.noteAlreadyExists
        }

        let note = noteURLs(pdf: folder.appendingPathComponent("\(name).pdf"))
        let stagingFolder = folder.appendingPathComponent(".notestogo-create-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: stagingFolder, withIntermediateDirectories: false)
        let stagedNote = noteURLs(pdf: stagingFolder.appendingPathComponent("\(name).pdf"))
        var publishedMarkup = false

        do {
            // Keep the intended final URLs if an interrupted operation leaves staging artifacts.
            try JSONEncoder().encode(note).write(to: stagingFolder.appendingPathComponent("note.json"), options: .atomic)
            let document = MultiPageDocument(template: .empty)
            try pdfGenerator.write(at: stagedNote.pdf, document: document)
            try await documentRepository.save(document, at: stagedNote.markup)

            // moveItem refuses replacement. Publish the PDF last so incomplete notes stay hidden.
            try publishFile(stagedNote.markup, note.markup)
            publishedMarkup = true
            try publishFile(stagedNote.pdf, note.pdf)
        } catch {
            let creationError = error
            do {
                if publishedMarkup { try fm.removeItem(at: note.markup) }
                try fm.removeItem(at: stagingFolder)
            } catch {
                throw EditorError.creationCleanupFailed(stagingFolder)
            }
            throw creationError
        }

        // Cleanup failure cannot invalidate the complete pair; leftovers stay hidden and identified.
        try? fm.removeItem(at: stagingFolder)
        return note
    }

    private func noteURLs(pdf: URL) -> Note {
        let markup = pdf.deletingLastPathComponent()
            .appendingPathComponent(".\(pdf.deletingPathExtension().lastPathComponent).markup")
        return Note(pdf: pdf, markup: markup)
    }
}
