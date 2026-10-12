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
        let markupData: Data?
        do {
            markupData = try Data(contentsOf: note.markup)
        } catch where Self.isMissingFile(error) {
            // Only an absent sidecar permits PDF-only initialization. Read failures do not.
            markupData = nil
        }

        let document: MultiPageDocument?
        if let markupData {
            do {
                document = try JSONDecoder().decode(StoredDocument.self, from: markupData).document
            } catch let error as EditorError {
                throw error
            } catch {
                throw EditorError.corruptDocument
            }
        } else {
            document = nil
        }

        let pdfData: Data
        do {
            pdfData = try Data(contentsOf: note.pdf)
        } catch where Self.isMissingFile(error) {
            throw EditorError.documentNotFound
        }
        guard let pdf = PDFDocument(data: pdfData), pdf.pageCount > 0 else {
            throw EditorError.invalidPDF
        }
        if let document { return document }

        var pages: [Page] = []
        for index in 0..<pdf.pageCount {
            guard let page = pdf.page(at: index) else { throw EditorError.invalidPDF }
            let bounds = page.bounds(for: .mediaBox)
            guard bounds.width.isFinite, bounds.height.isFinite,
                  bounds.width > 0, bounds.height > 0 else { throw EditorError.invalidPDF }
            pages.append(Page(bounds: bounds, background: .plain(.white)))
        }
        return MultiPageDocument(pages: pages)
    }

    private static func isMissingFile(_ error: Error) -> Bool {
        let error = error as NSError
        return error.domain == NSCocoaErrorDomain
            && (error.code == CocoaError.fileReadNoSuchFile.rawValue || error.code == CocoaError.fileNoSuchFile.rawValue)
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
