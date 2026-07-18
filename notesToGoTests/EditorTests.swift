import Foundation
import Testing
import Dependencies
import FluxTestStore

@testable import notesToGo

@MainActor
class EditorTests {
    // MARK: - setup
    let ANY_DOCUMENT = MultiPageDocument(template: .empty)
    let ANY_NOTE = Note(pdf: URL(string: "MyFile.pdf")!, markup: URL(string: ".MyFile.markup")!)
    
    @Dependency(\.documentRepository) var repo
    
    let store: TestStore<EditorFeature>
    
    init() {
        DependencyValues.setMode(.mock)
        
        store = .init(state: .init(), middlewares: [
            DocumentMiddleware().handle
        ])
    }
    
    deinit {
        store.tearDown()
    }
    
    // MARK: - document
    @Test
    func open_loadsDocFromRepo() async throws {
        try await repo.save(ANY_DOCUMENT, at: ANY_NOTE.markup)
        
        store.dispatch(.openNote(ANY_NOTE)) {
            $0.note = self.ANY_NOTE;
            $0.mode = .write
            $0.isLoading = true
        }
        
        await store.receive(.documentLoaded(ANY_DOCUMENT)) {
            $0.document = self.ANY_DOCUMENT;
            $0.isLoading = false
        }
    }
    
    @Test
    func save_whenDocWasLoaded_savesDocToRepo() async throws {
        try await givenDocumentWasLoaded(ANY_DOCUMENT, at: ANY_NOTE.markup)
        
        store.dispatch(.save(.init())) { $0.isLoading = true }
        
        await store.receive(.saved) { $0.isLoading = false }
    }
    
    @Test
    func pageAppended_addsNewPageToDoc() async throws {
        try await givenDocumentWasLoaded(ANY_DOCUMENT, at: ANY_NOTE.markup)
        let page = Page.empty(id: UUID())
        
        store.dispatch(.pageAppended(page)) {
            $0.document?.pages.append(page)
        }
        
        await save()
    }
    
    @Test
    func insertCopyPasteAndMovePage_updatesDocument() async throws {
        var doc = MultiPageDocument(template: .empty)
        doc.pages.append(.empty)
        try await givenDocumentWasLoaded(doc, at: ANY_NOTE.markup)
        
        let firstID = try #require(store.state.document?.pages.first?.id)
        let secondID = try #require(store.state.document?.pages.last?.id)
        
        store.dispatch(.copyPage(firstID)) {
            $0.copiedPage = doc.pages.first
        }
        
        let oldCount = try #require(store.state.document?.pages.count)
        let pastedPage = try #require(doc.pages.first?.duplicated(id: UUID()))
        store.dispatch(.pagePasted(after: secondID, page: pastedPage)) {
            $0.document?.pages.append(pastedPage)
        }
        #expect(store.state.document?.pages.count == oldCount + 1)
        
        let pastedID = try #require(store.state.document?.pages.last?.id)
        store.dispatch(.movePage(source: pastedID, destination: firstID)) {
            guard var pages = $0.document?.pages,
                  let sourceIndex = pages.firstIndex(where: { $0.id == pastedID }),
                  let destinationIndex = pages.firstIndex(where: { $0.id == firstID }) else { return }
            
            let page = pages.remove(at: sourceIndex)
            let insertionIndex = sourceIndex < destinationIndex ? destinationIndex - 1 : destinationIndex
            pages.insert(page, at: insertionIndex)
            $0.document?.pages = pages
        }
        #expect(store.state.document?.pages.map(\.id) == [pastedID, firstID, secondID])
        
        await save()
    }
    
    func givenDocumentWasLoaded(_ doc: MultiPageDocument, at path: URL) async throws {
        try await repo.save(doc, at: path)
        
        store.dispatch(.openNote(ANY_NOTE)) {
            $0.note = self.ANY_NOTE;
            $0.mode = .write
            $0.isLoading = true
        }
        
        await store.receive(.documentLoaded(doc)) {
            $0.document = doc;
            $0.isLoading = false
        }
    }
 
    
    func save() async {
        store.dispatch(.save(.init())) { $0.isLoading = true }
        await store.receive(.saved) { $0.isLoading = false }
    }
    
    // MARK: - editor mode
    @Test
    func toggleEditMode_togglesBetweenReadAndWriteMode() {
        store.dispatch(.toggleEditMode) { $0.mode = .write }
        store.dispatch(.toggleEditMode) { $0.mode = .read }
    }
}
