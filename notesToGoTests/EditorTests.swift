import FactoryKit
import FactoryTesting
import Foundation
import Router
import Testing
@testable import notesToGo

@Suite(.container)
@MainActor
struct EditorTests {
    @Test
    func open_loadsDocFromRepo() async throws {
        let document = MultiPageDocument(template: .empty)
        let editor = try await loadedEditor(document)

        #expect(editor.state.document == document)
        #expect(!editor.state.hasUnsavedChanges)
    }

    @Test
    func save_whenContentChanged_savesDocToRepo() async throws {
        let document = MultiPageDocument(template: .empty)
        let editor = try await loadedEditor(document)
        var state = editor.state

        var expected = state
        expected.hasUnsavedChanges = true
        EditorFeature().reduce(&state, .canvasChanged(document.pages[0].id))
        #expect(state == expected)
        try await save(&state, using: editor.middleware, repository: editor.repository)
    }

    @Test
    func pageAppended_addsNewPageToDoc() async throws {
        let document = MultiPageDocument(template: .empty)
        let editor = try await loadedEditor(document)
        var state = editor.state
        let page = Page.empty(id: UUID())

        var expected = state
        expected.document?.pages.append(page)
        expected.hasUnsavedChanges = true
        EditorFeature().reduce(&state, .pageAppended(page))

        #expect(state == expected)
        try await save(&state, using: editor.middleware, repository: editor.repository)
    }

    @Test
    func insertCopyPasteAndMovePage_updatesDocument() async throws {
        var document = MultiPageDocument(template: .empty)
        document.pages.append(.empty)
        let editor = try await loadedEditor(document)
        var state = editor.state
        let feature = EditorFeature()
        let first = document.pages[0]
        let second = document.pages[1]

        var expected = state
        expected.copiedPage = first
        feature.reduce(&state, .copyPage(first.id))
        #expect(state == expected)

        let pasted = first.duplicated(id: UUID())
        expected.document?.pages.append(pasted)
        expected.hasUnsavedChanges = true
        feature.reduce(&state, .pagePasted(after: second.id, page: pasted))
        #expect(state == expected)

        expected.document?.pages = [pasted, first, second]
        feature.reduce(&state, .movePage(source: pasted.id, destination: first.id))
        #expect(state == expected)
        try await save(&state, using: editor.middleware, repository: editor.repository)
    }

    @Test
    func toggleEditMode_togglesBetweenReadAndWriteMode() {
        var state = EditorFeature.State()
        let feature = EditorFeature()

        var expected = state
        expected.mode = .write
        feature.reduce(&state, .toggleEditMode)
        #expect(state == expected)
        expected.mode = .read
        feature.reduce(&state, .toggleEditMode)
        #expect(state == expected)
    }

    /// Create/register services inside the test scope, then explicitly await every
    /// middleware call. No unstructured effects or deinit-based teardown escape a test.
    private func loadedEditor(_ document: MultiPageDocument) async throws -> (
        state: EditorFeature.State,
        repository: InMemoryDocumentRepository,
        middleware: DocumentMiddleware
    ) {
        let repository = InMemoryDocumentRepository()
        Container.shared.documentRepository.register { repository }
        Container.shared.router.register { MyRouter(root: .explorer(.dashboard(path: nil))) }
        let middleware = DocumentMiddleware()
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let note = Note(pdf: folder.appendingPathComponent("Editor.pdf"), markup: folder.appendingPathComponent(".Editor.markup"))
        try await repository.save(document, at: note.markup)
        let feature = EditorFeature()
        var state = EditorFeature.State()
        let open = EditorFeature.Action.openNote(note)
        var expected = state
        expected.note = note
        expected.mode = .write
        expected.isLoading = true
        feature.reduce(&state, open)
        #expect(state == expected)

        let loaded = try #require(await middleware.handle(state: state, action: open))
        #expect(loaded == .documentLoaded(document))
        expected.document = document
        expected.isLoading = false
        feature.reduce(&state, loaded)
        #expect(state == expected)
        #expect(middleware.router.stack.stack == [.editor(.editor)])
        #expect(await middleware.handle(state: state, action: loaded) == nil)
        return (state, repository, middleware)
    }

    private func save(
        _ state: inout EditorFeature.State,
        using middleware: DocumentMiddleware,
        repository: InMemoryDocumentRepository
    ) async throws {
        let document = try #require(state.document)
        let note = try #require(state.note)
        let feature = EditorFeature()
        let id = UUID()
        let action = EditorFeature.Action.save([:], requestID: id)
        var expected = state
        expected.saveRequest = .init(id: id, note: note, document: document)
        feature.reduce(&state, action)
        #expect(state == expected)

        let saved = try #require(await middleware.handle(state: state, action: action))
        #expect(saved == .saved(id))
        expected.saveRequest = nil
        expected.hasUnsavedChanges = false
        feature.reduce(&state, saved)
        #expect(state == expected)
        #expect(try await repository.load(note) == document)
        #expect(await middleware.handle(state: state, action: saved) == nil)
    }
}
