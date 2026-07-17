import Foundation
import Testing
import Dependencies
import FluxTestStore

@testable import notesToGo

@MainActor
class EditorTests {
    // MARK: - setup
    let ANY_PATH = URL(string: "MyFile")!
    let ANY_DOCUMENT = MultiPageDocument(template: .empty)
    
    var repo: DocumentRepositoryProtocol
    
    let store: TestStore<EditorFeature>
    
    init() {
        repo = InMemoryDocumentRepository()
        
        store = .init(state: .init(), middlewares: [
            DocumentMiddleware(repo: repo).handle
        ])
    }
    
    deinit {
        store.tearDown()
    }
    
    // MARK: - document
    @Test
    func open_loadsDocFromRepo() async throws {
        try await repo.save(ANY_DOCUMENT, at: ANY_PATH)
        
        store.dispatch(.open(ANY_PATH)) {
            $0.path = self.ANY_PATH;
            $0.isLoading = true
        }
        
        await store.receive(.documentLoaded(ANY_DOCUMENT)) {
            $0.document = self.ANY_DOCUMENT;
            $0.isLoading = false
        }
    }
    
    @Test
    func save_whenDocWasLoaded_savesDocToRepo() async throws {
        try await givenDocumentWasLoaded(ANY_DOCUMENT, at: ANY_PATH)
        
        store.dispatch(.save(.init())) { $0.isLoading = true }
        
        await store.receive(.saved) { $0.isLoading = false }
    }
    
    @Test
    func addPageTapped_addsNewPageToDoc() async throws {
        try await givenDocumentWasLoaded(ANY_DOCUMENT, at: ANY_PATH)
        
        store.dispatch(.addPageTapped) {
            $0.document?.pages.append(.empty)
        }
    }
    
    @Test
    func insertCopyPasteAndMovePage_updatesDocument() async throws {
        var doc = MultiPageDocument(template: .empty)
        doc.pages.append(.empty)
        try await givenDocumentWasLoaded(doc, at: ANY_PATH)
        
        let firstID = try #require(store.state.document?.pages.first?.id)
        let secondID = try #require(store.state.document?.pages.last?.id)
        
        store.dispatch(.copyPage(firstID)) {
            $0.copiedPage = doc.pages.first
        }
        
        let oldCount = try #require(store.state.document?.pages.count)
        store.dispatch(.pastePage(after: secondID))
        #expect(store.state.document?.pages.count == oldCount + 1)
        
        let pastedID = try #require(store.state.document?.pages.last?.id)
        store.dispatch(.movePage(source: pastedID, destination: firstID))
        #expect(store.state.document?.pages.first?.id == pastedID)
    }
    
    func givenDocumentWasLoaded(_ doc: MultiPageDocument, at path: URL) async throws {
        try await repo.save(doc, at: path)
        
        store.dispatch(.open(path)) {
            $0.path = path;
            $0.isLoading = true
        }
        
        await store.receive(.documentLoaded(doc)) {
            $0.document = doc;
            $0.isLoading = false
        }
    }
 
    // MARK: - editor mode
    @Test
    func toggleEditMode_togglesBetweenReadAndWriteMode() {
        store.dispatch(.toggleEditMode) { $0.mode = .write }
        store.dispatch(.toggleEditMode) { $0.mode = .read }
    }
}
