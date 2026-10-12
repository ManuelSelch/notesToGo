import Foundation
import PDFKit
import PaperKit

nonisolated enum Document: Identifiable, Hashable, Sendable {
    case note(Note)
    case folder(URL)
    
    var id: Self { self }
}

nonisolated struct Note: Identifiable, Hashable, Codable, Sendable {
    let pdf: URL
    let markup: URL
    
    var id: URL { markup.absoluteURL }
}

/// load & save documents & folders
class Explorer {
    static let blankTemplatePDFCreator = "NotesToGo.BlankTemplate"
    
    let fm: FileManager
    private let documentRepository: DocumentRepositoryProtocol
    private let writePDF: (PDFDocument, URL) -> Bool
    private let publishFile: (URL, URL) throws -> Void

    init(
        documentRepository: DocumentRepositoryProtocol = DocumentRepository(),
        fileManager: FileManager = .default,
        writePDF: @escaping (PDFDocument, URL) -> Bool = { $0.write(to: $1) },
        publishFile: ((URL, URL) throws -> Void)? = nil
    ) {
        self.documentRepository = documentRepository
        fm = fileManager
        self.writePDF = writePDF
        self.publishFile = publishFile ?? { try fileManager.moveItem(at: $0, to: $1) }
    }
    
    static let quickNoteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    func loadAllDocs(in folder: URL? = nil) async throws -> [Document] {
        var docs: [Document] = []
        
        docs.append(contentsOf: try loadNotes(in: folder).map { .note($0) })
        docs.append(contentsOf: try loadFolders(in: folder).map { .folder($0) })
        
        return docs
    }
    
    func loadNotes(in folder: URL? = nil) throws -> [Note] {
        let folder = folder ?? rootFolder()
        let files = try fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)

        return files
            .filter { $0.pathExtension.lowercased() == "pdf" }
            .map { pdfFile in
                let markupFile = folder.appendingPathComponent(".\(pdfFile.deletingPathExtension().lastPathComponent).markup")
                return Note(pdf: pdfFile, markup: markupFile)
            }
    }
    
    func loadFolders(in folder: URL? = nil) throws -> [URL] {
        let root = folder ?? rootFolder()
        let folders = try fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

        return folders.filter { url in
            var isDir: ObjCBool = false
            return fm.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
        }
    }
    
    // MARK: - add note
    func addNote(at folder: URL? = nil, name: String) async throws -> Note {
        let name = try NoteName.validated(name)
        let folder = folder ?? rootFolder()
        try ensureFolderExists(folder)
        guard try !noteNameExists(name, in: folder) else { throw EditorError.noteAlreadyExists }

        let note = noteURLs(in: folder, name: name)
        let stagingFolder = folder.appendingPathComponent(".notestogo-create-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: stagingFolder, withIntermediateDirectories: false)
        let stagedNote = noteURLs(in: stagingFolder, name: name)
        var publishedMarkup = false

        do {
            // Retain the intended final URLs if an interrupted operation leaves staging artifacts.
            try JSONEncoder().encode(note).write(to: stagingFolder.appendingPathComponent("note.json"), options: .atomic)
            let document = MultiPageDocument(template: .empty)
            try createEmptyPDF(at: stagedNote.pdf, document: document)
            try await documentRepository.save(document, at: stagedNote.markup)

            // moveItem refuses to replace a destination created while serialization was awaiting.
            // Publish the PDF last so the explorer does not show an incomplete note.
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

        // A cleanup failure here cannot invalidate the already complete note pair.
        // Leftovers are hidden and identified by note.json rather than exposed as notes.
        try? fm.removeItem(at: stagingFolder)
        return note
    }
    
    func addQuickNote(at folder: URL? = nil, date: Date = .now) async throws -> Note {
        let folder = folder ?? rootFolder()
        try ensureFolderExists(folder)
        let baseName = Self.quickNoteFormatter.string(from: date)
        let uniqueName = try uniqueNoteName(base: baseName, in: folder)
        return try await addNote(at: folder, name: uniqueName)
    }
    
    func inboxFolder() throws -> URL {
        let url = rootFolder().appendingPathComponent("QuickNotes", isDirectory: true)
        try ensureFolderExists(url)
        return url
    }
    
    func addFolder(at folder: URL? = nil, name: String) throws -> URL {
        let name = try NoteName.validated(name)
        let parent = folder ?? rootFolder()
        try ensureFolderExists(parent)
        
        let folderURL = parent.appendingPathComponent(uniqueFolderName(base: name, in: parent), isDirectory: true)
        try fm.createDirectory(at: folderURL, withIntermediateDirectories: false)
        return folderURL
    }
    
    func uniqueNoteName(base: String, in folder: URL? = nil) throws -> String {
        let folder = folder ?? rootFolder()
        var candidate = base
        var index = 2
        
        while try noteNameExists(candidate, in: folder) {
            candidate = "\(base) \(index)"
            index += 1
        }
        
        return candidate
    }
    
    func uniqueFolderName(base: String, in folder: URL? = nil) -> String {
        let folder = folder ?? rootFolder()
        var candidate = base
        var index = 2
        
        while fm.fileExists(atPath: folder.appendingPathComponent(candidate, isDirectory: true).path) {
            candidate = "\(base) \(index)"
            index += 1
        }
        
        return candidate
    }
    
    private func ensureFolderExists(_ folder: URL) throws {
        if !fm.fileExists(atPath: folder.path) {
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }
    }
    
    private func noteURLs(in folder: URL, name: String) -> Note {
        Note(
            pdf: folder.appendingPathComponent("\(name).pdf"),
            markup: folder.appendingPathComponent(".\(name).markup")
        )
    }

    private func noteNameExists(_ name: String, in folder: URL) throws -> Bool {
        let note = noteURLs(in: folder, name: name)
        let filenames = try fm.contentsOfDirectory(atPath: folder.path)
        return filenames.contains { filename in
            filename.caseInsensitiveCompare(note.pdf.lastPathComponent) == .orderedSame
                || filename.caseInsensitiveCompare(note.markup.lastPathComponent) == .orderedSame
        }
    }

    private func createEmptyPDF(at url: URL, document: MultiPageDocument) throws {
        let pdf = PDFDocument()
        for (index, page) in document.pages.enumerated() {
            let pdfPage = PDFPage()
            pdfPage.setBounds(page.markup.bounds, for: .mediaBox)
            pdf.insert(pdfPage, at: index)
        }
        pdf.documentAttributes = [PDFDocumentAttribute.creatorAttribute: Self.blankTemplatePDFCreator]
        guard writePDF(pdf, url) else { throw EditorError.pdfWriteFailed }
    }
    
    
    func rootFolder() -> URL {
        #if DEBUG
        do {
            if let root = try UITestStorage().root { return root }
        } catch {
            fatalError("Invalid UI-test storage configuration: \(error)")
        }
        #endif
        return fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
