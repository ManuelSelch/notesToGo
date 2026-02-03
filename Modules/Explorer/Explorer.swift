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
    
    func loadAllDocs(in folder: URL? = nil) async throws -> [Document] {
        var docs: [Document] = []
        
        docs.append(contentsOf: loadNotes(in: folder).map { .note($0) })
        docs.append(contentsOf: loadFolders(in: folder).map { .folder($0) })
        
        return docs
    }
    
    func loadNotes(in folder: URL? = nil) -> [Note] {
        let folder = folder ?? rootFolder()
        
        guard let files = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else { return [] }

        var results: [Note] = []

        for pdfFile in files where pdfFile.pathExtension == "pdf" {
            let markupFile = folder.appendingPathComponent(".\(pdfFile.deletingPathExtension().lastPathComponent).markup")
            if fm.fileExists(atPath: markupFile.path) {
                results.append(.init(pdf: pdfFile, markup: markupFile))
            }
        }

        return results
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
