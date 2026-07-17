import Foundation
import PDFKit
import PaperKit

enum Document: Identifiable, Hashable {
    case note(Note)
    case folder(URL)
    
    var id: Self { self }
}

struct Note: Identifiable, Hashable, Codable {
    let pdf: URL
    let markup: URL
    
    var id: URL { markup.absoluteURL }
}

/// load & save documents & folders
class Explorer {
    let fm = FileManager.default
    
    static let quickNoteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    func loadAllDocs(in folder: URL? = nil) async throws -> [Document] {
        var docs: [Document] = []
        
        docs.append(contentsOf: loadNotes(in: folder).map { .note($0) })
        docs.append(contentsOf: loadFolders(in: folder).map { .folder($0) })
        
        return docs
    }
    
    func loadNotes(in folder: URL? = nil) -> [Note] {
        let folder = folder ?? rootFolder()
        
        guard let files = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else { return [] }

        return files
            .filter { $0.pathExtension.lowercased() == "pdf" }
            .map { pdfFile in
                let markupFile = folder.appendingPathComponent(".\(pdfFile.deletingPathExtension().lastPathComponent).markup")
                return Note(pdf: pdfFile, markup: markupFile)
            }
    }
    
    func loadFolders(in folder: URL? = nil) -> [URL] {
        let root = folder ?? rootFolder()
        
        guard let folders = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
            return []
        }

        return folders.filter { url in
            var isDir: ObjCBool = false
            return fm.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
        }
    }
    
    // MARK: - add note
    func addNote(at folder: URL? = nil, name: String) async throws -> Note {
        let folder = folder ?? rootFolder()
        
        try ensureFolderExists(folder)
        
        let pdf = await createEmptyPDF(at: folder, name)
        let markup = try await createEmptyMarkup(at: folder, name)
        
        
        return Note(pdf: pdf, markup: markup)
    }
    
    func addQuickNote(at folder: URL? = nil, date: Date = .now) async throws -> Note {
        let baseName = Self.quickNoteFormatter.string(from: date)
        let uniqueName = uniqueNoteName(base: baseName, in: folder)
        return try await addNote(at: folder, name: uniqueName)
    }
    
    func addFolder(at folder: URL? = nil, name: String) throws -> URL {
        let parent = folder ?? rootFolder()
        try ensureFolderExists(parent)
        
        let folderURL = parent.appendingPathComponent(uniqueFolderName(base: name, in: parent), isDirectory: true)
        try fm.createDirectory(at: folderURL, withIntermediateDirectories: false)
        return folderURL
    }
    
    func uniqueNoteName(base: String, in folder: URL? = nil) -> String {
        let folder = folder ?? rootFolder()
        var candidate = base
        var index = 2
        
        while fm.fileExists(atPath: folder.appendingPathComponent("\(candidate).pdf").path)
            || fm.fileExists(atPath: folder.appendingPathComponent(".\(candidate).markup").path) {
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
    
    private func createEmptyPDF(at folder: URL, _ name: String) async -> URL {
        let pdfURL = folder.appendingPathComponent("\(name).pdf")
        
        let pdf = PDFDocument()
        pdf.insert(PDFPage(), at: 0)
        pdf.write(to: pdfURL)
        
        return pdfURL
    }
    
    private func createEmptyMarkup(at folder: URL, _ name: String) async throws -> URL {
        // create empty markup
        let markupURL = folder.appendingPathComponent(".\(name).markup")
        
        let markup = PaperMarkup(bounds: .init(origin: .zero, size: .init(width: 350, height: 670)))
        let data = try await markup.dataRepresentation()
        try data.write(to: markupURL)
        
        return markupURL
    }
    
    
    func rootFolder() -> URL {
        return fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
