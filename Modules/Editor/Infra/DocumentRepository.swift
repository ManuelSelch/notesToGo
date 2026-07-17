import Foundation
import Dependencies
import PaperKit
import PDFKit

/// repository to load and save documents
protocol DocumentRepositoryProtocol {
    func save(_ document: MultiPageDocument, at path: URL) async throws
    func load(_ path: URL) async throws -> MultiPageDocument
}

class DocumentRepository: DocumentRepositoryProtocol {
    func save(_ document: MultiPageDocument, at path: URL) async throws {
        var markupDataList: [Data] = []
        for page in document.pages {
            markupDataList.append(try await page.markup.dataRepresentation())
        }
        
        let encoder = JSONEncoder()
        encoder.userInfo[.markupDataKey] = markupDataList
        let data = try encoder.encode(document)
        try data.write(to: path, options: .atomic)
    }
    
    func load(_ path: URL) async throws -> MultiPageDocument {
        if FileManager.default.fileExists(atPath: path.path) {
            let data = try Data(contentsOf: path)
            return try JSONDecoder().decode(MultiPageDocument.self, from: data)
        }
        
        guard let pdf = PDFDocument(url: pdfURL(forMarkupURL: path)) else {
            throw EditorError.documentNotFound
        }
        
        return MultiPageDocument(
            pages: (0..<pdf.pageCount).compactMap { index in
                guard let page = pdf.page(at: index) else { return nil }
                return Page(bounds: page.bounds(for: .mediaBox), background: .plain(.white))
            }
        )
    }
    
    private func pdfURL(forMarkupURL markupURL: URL) -> URL {
        let markupName = markupURL.deletingPathExtension().lastPathComponent
        let pdfName = markupName.hasPrefix(".") ? String(markupName.dropFirst()) : markupName
        return markupURL.deletingLastPathComponent().appendingPathComponent("\(pdfName).pdf")
    }
}

class InMemoryDocumentRepository: DocumentRepositoryProtocol {
    private var documents: [URL: MultiPageDocument] = [:]
    
    func save(_ document: MultiPageDocument, at path: URL) async throws {
        documents[path] = document
    }
    
    func load(_ path: URL) async throws -> MultiPageDocument {
        guard let doc = documents[path] else { throw EditorError.documentNotFound }
        return doc
    }
}

struct DocumentRepositoryKey: DependencyKey {
    static var liveValue: DocumentRepositoryProtocol = DocumentRepository()
    static var mockValue: DocumentRepositoryProtocol = InMemoryDocumentRepository()
}

extension DependencyValues {
    var documentRepository: DocumentRepositoryProtocol { Self[DocumentRepositoryKey.self] }
}

extension CodingUserInfoKey {
    static let markupDataKey = CodingUserInfoKey(rawValue: "markupData")!
}
