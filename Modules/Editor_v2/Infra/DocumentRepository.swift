import Foundation
import Dependencies

/// repository to load and save documents
protocol DocumentRepositoryProtocol {
    func save(_ document: MultiPageDocument, at path: URL) async throws
    func load(_ path: URL) async throws -> MultiPageDocument
}

actor DocumentRepository: DocumentRepositoryProtocol {
    func save(_ document: MultiPageDocument, at path: URL) throws {
        fatalError("not implemented yet")
    }
    
    func load(_ path: URL) throws -> MultiPageDocument {
        fatalError("not implemented yet")
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
