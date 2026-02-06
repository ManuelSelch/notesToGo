import Foundation
import Testing
import Dependencies
import FluxTestStore

@testable import notesToGo

@MainActor
class EditorTests {
    // MARK: - setup
    let ANY_PATH = URL(string: "MyFile")!
    let ANY_DOCUMENT = MultiPageDocument(
        pageSize: .init(width: 100, height: 100),
        background: .plain(.white)
    )
    
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
        
        store.dispatch(.save) { $0.isLoading = true }
        
        await store.receive(.saved) { $0.isLoading = false }
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
    
    @Test
    func pageChanged_updatesCurrentPage() {
        store.dispatch(.pageChanged(1)) { $0.currentPage = 1 }
    }
}
