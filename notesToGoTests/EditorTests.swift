import FactoryKit
import FactoryTesting
import FluxTestStore
import Foundation
import Router
import Testing
@testable import notesToGo

@Suite(.container { @MainActor container in
    container.documentRepository.register { InMemoryDocumentRepository() }
    container.router.register { MyRouter(root: .explorer(.dashboard(path: nil))) }
})
@MainActor
struct EditorTests {
    private let document = MultiPageDocument(template: .empty)
    private let note = Note(
        pdf: URL(fileURLWithPath: "/EditorTests/Note.pdf"),
        markup: URL(fileURLWithPath: "/EditorTests/.Note.markup")
    )
    private var repository: DocumentRepositoryProtocol { Container.shared.documentRepository() }

    @Test
    func open_loadsDocFromRepo() async throws {
        let store = makeStore()
        defer { store.tearDown() }
        try await givenDocumentWasLoaded(document, in: store)
        await store.finish()
    }

    @Test
    func save_whenContentChanged_savesDocToRepo() async throws {
        let store = makeStore()
        defer { store.tearDown() }
        try await givenDocumentWasLoaded(document, in: store)
        store.dispatch(.canvasChanged(document.pages[0].id)) { $0.hasUnsavedChanges = true }
        try await save(store)
        await store.finish()
    }

    @Test
    func pageAppended_addsNewPageToDoc() async throws {
        let store = makeStore()
        defer { store.tearDown() }
        try await givenDocumentWasLoaded(document, in: store)
        let page = Page.empty(id: UUID())

        store.dispatch(.pageAppended(page)) {
            $0.document?.pages.append(page)
            $0.hasUnsavedChanges = true
        }

        try await save(store)
        await store.finish()
    }

    @Test
    func insertCopyPasteAndMovePage_updatesDocument() async throws {
        let store = makeStore()
        defer { store.tearDown() }
        var document = document
        document.pages.append(.empty)
        try await givenDocumentWasLoaded(document, in: store)
        let first = document.pages[0]
        let second = document.pages[1]

        store.dispatch(.copyPage(first.id)) { $0.copiedPage = first }
        let pasted = first.duplicated(id: UUID())
        store.dispatch(.pagePasted(after: second.id, page: pasted)) {
            $0.document?.pages.append(pasted)
            $0.hasUnsavedChanges = true
        }
        store.dispatch(.movePage(source: pasted.id, destination: first.id)) {
            $0.document?.pages = [pasted, first, second]
        }

        try await save(store)
        await store.finish()
    }

    @Test
    func toggleEditMode_togglesBetweenReadAndWriteMode() async {
        let store = makeStore()
        defer { store.tearDown() }
        store.dispatch(.toggleEditMode) { $0.mode = .write }
        store.dispatch(.toggleEditMode) { $0.mode = .read }
        await store.finish()
    }

    private func makeStore() -> TestStore<EditorFeature> {
        .init(state: .init(), middlewares: [DocumentMiddleware().handle])
    }

    private func givenDocumentWasLoaded(_ document: MultiPageDocument, in store: TestStore<EditorFeature>) async throws {
        try await repository.save(document, at: note.markup)
        store.dispatch(.openNote(note)) {
            $0.note = note
            $0.mode = .write
            $0.isLoading = true
        }
        await store.receive(.documentLoaded(document)) {
            $0.document = document
            $0.isLoading = false
        }
    }

    private func save(_ store: TestStore<EditorFeature>) async throws {
        let id = UUID()
        let expectedDocument = try #require(store.state.document)
        store.dispatch(.save([:], requestID: id)) {
            $0.saveRequest = .init(id: id, note: note, document: expectedDocument)
        }
        await store.receive(.saved(id)) {
            $0.saveRequest = nil
            $0.hasUnsavedChanges = false
        }
        #expect(try await repository.load(note) == expectedDocument)
    }
}
