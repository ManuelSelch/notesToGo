import Foundation
import Dependencies
import PaperKit

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
    
    func load(_ path: URL) throws -> MultiPageDocument {
        let data = try Data(contentsOf: path)
        return try JSONDecoder().decode(MultiPageDocument.self, from: data)
    }
}

class InMemoryDocumentRepository: DocumentRepositoryProtocol {
    private var documents: [URL: MultiPageDocument] = [:]
    
    func save(_ document: MultiPageDocument, at path: URL) throws {
        documents[path] = document
    }
    
    func load(_ path: URL) throws -> MultiPageDocument {
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
