import Foundation
import Dependencies
import PaperKit
import PDFKit

/// repository to load and save documents
protocol DocumentRepositoryProtocol {
    func save(_ document: MultiPageDocument, at path: URL) async throws
    func load(_ note: Note) async throws -> MultiPageDocument
}

class DocumentRepository: DocumentRepositoryProtocol {
    func save(_ document: MultiPageDocument, at path: URL) async throws {
        var markupDataList: [Data] = []
        for page in document.pages {
            markupDataList.append(try await page.markup.dataRepresentation())
        }
        
        let encoder = JSONEncoder()
        encoder.userInfo[.markupDataKey] = markupDataList
        let data = try encoder.encode(StoredDocument(document: document))
        try data.write(to: path, options: .atomic)
    }
    
    func load(_ note: Note) async throws -> MultiPageDocument {
        if FileManager.default.fileExists(atPath: note.markup.path) {
            let data = try Data(contentsOf: note.markup)
            return try JSONDecoder().decode(StoredDocument.self, from: data).document
        }
        
        guard let pdf = PDFDocument(url: note.pdf) else {
            throw EditorError.documentNotFound
        }
        
        return MultiPageDocument(
            pages: (0..<pdf.pageCount).compactMap { index in
                guard let page = pdf.page(at: index) else { return nil }
                return Page(bounds: page.bounds(for: .mediaBox), background: .plain(.white))
            }
        )
    }
    
    /// The only supported on-disk format. Check the version before decoding page data.
    private struct StoredDocument: Codable {
        static let currentVersion = 1
        let formatVersion: Int
        let document: MultiPageDocument

        init(document: MultiPageDocument) {
            formatVersion = Self.currentVersion
            self.document = document
        }

        private enum CodingKeys: String, CodingKey {
            case formatVersion, document
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            guard let version = try container.decodeIfPresent(Int.self, forKey: .formatVersion) else {
                throw EditorError.missingFormatVersion
            }
            guard version == Self.currentVersion else {
                throw EditorError.unsupportedFormatVersion(version)
            }
            formatVersion = version
            document = try container.decode(MultiPageDocument.self, forKey: .document)
        }
    }
}

class InMemoryDocumentRepository: DocumentRepositoryProtocol {
    private var documents: [URL: MultiPageDocument] = [:]
    
    func save(_ document: MultiPageDocument, at path: URL) async throws {
        documents[path] = document
    }
    
    func load(_ note: Note) async throws -> MultiPageDocument {
        guard let doc = documents[note.markup] else { throw EditorError.documentNotFound }
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
