import FactoryKit
import FactoryTesting
import Foundation
import PaperKit
import Testing
@testable import notesToGo

@Suite(.container)
@MainActor
struct ManualSaveTests {
    let feature = EditorFeature()
    let note = Note(pdf: URL(fileURLWithPath: "/tmp/Manual.pdf"), markup: URL(fileURLWithPath: "/tmp/.Manual.markup"))

    func loadedState() -> EditorFeature.State {
        var state = EditorFeature.State()
        feature.reduce(&state, .openNote(note))
        feature.reduce(&state, .documentLoaded(MultiPageDocument(template: .empty)))
        return state
    }

    @Test func opensCleanAndOnlyActualContentChangesEnableSave() throws {
        var state = loadedState()
        let id = try #require(state.document?.pages.first?.id)
        #expect(!state.hasUnsavedChanges)
        #expect(!state.canSave)
        for action: EditorFeature.Action in [.toolSelected(.eraser), .toggleFocusMode, .toggleFocusMode, .copyPage(id), .captureMarkups([:]), .movePage(source: id, destination: id)] {
            feature.reduce(&state, action)
            #expect(!state.hasUnsavedChanges)
        }
        feature.reduce(&state, .canvasChanged(UUID()))
        #expect(!state.canSave)
        feature.reduce(&state, .canvasChanged(id))
        #expect(state.canSave)
        feature.reduce(&state, .openNote(note))
        #expect(!state.hasUnsavedChanges)
        #expect(!state.canSave)
        feature.reduce(&state, .documentLoadFailed(OperationFailure(EditorError.corruptDocument)))
        feature.reduce(&state, .save([:]))
        #expect(!state.isSaving)
    }

    @Test func pageMutationsMarkDirtyButNoOpMovesDoNot() throws {
        var state = loadedState()
        let first = try #require(state.document?.pages.first?.id)
        let second = Page.empty(id: UUID())
        feature.reduce(&state, .pageAppended(second))
        #expect(state.hasUnsavedChanges)
        state.hasUnsavedChanges = false
        feature.reduce(&state, .movePage(source: first, destination: second.id))
        #expect(!state.hasUnsavedChanges) // Moving immediately before the next page changes nothing.
        feature.reduce(&state, .movePage(source: second.id, destination: first))
        #expect(state.hasUnsavedChanges)
        state.hasUnsavedChanges = false
        feature.reduce(&state, .pageInserted(after: first, page: .empty))
        #expect(state.hasUnsavedChanges)
        state.hasUnsavedChanges = false
        feature.reduce(&state, .pagePasted(after: first, page: .empty))
        #expect(state.hasUnsavedChanges)
    }

    @Test func saveCapturesCanvasAndBlocksEditsUntilMatchingCompletion() throws {
        var state = loadedState()
        let page = try #require(state.document?.pages.first)
        feature.reduce(&state, .canvasChanged(page.id))
        var markup = page.markup
        markup.insertNewLine(configuration: .init(type: .rectangle), from: .init(x: 10, y: 10), to: .init(x: 80, y: 80))
        let id = UUID()
        feature.reduce(&state, .save([page.id: markup], requestID: id))
        #expect(state.isSaving)
        #expect(!state.canSave)
        #expect(state.saveRequest?.document.pages.first?.markup == markup)
        #expect(state.saveRequest?.note == note)
        let savingState = state
        for action: EditorFeature.Action in [.save([:], requestID: UUID()), .canvasChanged(page.id), .pageAppended(.empty), .movePage(source: page.id, destination: UUID()), .captureMarkups([page.id: page.markup]), .openNote(note)] {
            feature.reduce(&state, action)
            #expect(state == savingState)
        }
        feature.reduce(&state, .saved(UUID()))
        #expect(state == savingState)
        feature.reduce(&state, .saved(id))
        #expect(!state.isSaving)
        #expect(!state.hasUnsavedChanges)
        #expect(!state.canSave)
        #expect(state.document?.pages.first?.markup == markup)
    }

    @Test func failedSaveRetainsSnapshotAndCanRetry() throws {
        var state = loadedState()
        feature.reduce(&state, .pageAppended(.empty))
        let original = state.document
        let id = UUID()
        feature.reduce(&state, .save([:], requestID: id))
        let failure = OperationFailure(CocoaError(.fileWriteNoPermission))
        feature.reduce(&state, .savedFailed(id, failure))
        #expect(!state.isSaving)
        #expect(state.hasUnsavedChanges)
        #expect(state.canSave)
        #expect(state.document == original)
        #expect(state.saveFailure == failure)
        let retry = UUID()
        feature.reduce(&state, .save([:], requestID: retry))
        #expect(state.saveFailure == nil)
        feature.reduce(&state, .saved(id))
        #expect(state.isSaving)
        feature.reduce(&state, .saved(retry))
        #expect(!state.hasUnsavedChanges)
    }

    @Test func cleanSaveAndGridCaptureDoNotWrite() async throws {
        let repo = RecordingSaveRepository()
        Container.shared.documentRepository.register { repo }
        let middleware = DocumentMiddleware()
        var state = loadedState()
        let cleanSave = EditorFeature.Action.save([:])
        feature.reduce(&state, cleanSave)
        #expect(await middleware.handle(state: state, action: cleanSave) == nil)
        feature.reduce(&state, .captureMarkups([:]))
        #expect(await middleware.handle(state: state, action: .captureMarkups([:])) == nil)
        #expect(repo.snapshots.isEmpty)

        feature.reduce(&state, .pageAppended(.empty))
        let save = EditorFeature.Action.save([:])
        feature.reduce(&state, save)
        let result = try #require(await middleware.handle(state: state, action: save))
        #expect(repo.snapshots == [state.document!])
        #expect(repo.paths == [note.markup])
        feature.reduce(&state, result)
        #expect(!state.hasUnsavedChanges)
    }

    @Test func duplicateSaveActionCannotReachRepository() async throws {
        var state = loadedState()
        feature.reduce(&state, .pageAppended(.empty))
        let first = EditorFeature.Action.save([:])
        let second = EditorFeature.Action.save([:])
        feature.reduce(&state, first)
        feature.reduce(&state, second)
        let repo = RecordingSaveRepository()
        Container.shared.documentRepository.register { repo }
        let middleware = DocumentMiddleware()
        #expect(await middleware.handle(state: state, action: second) == nil)
        #expect(await middleware.handle(state: state, action: first) != nil)
        #expect(repo.snapshots.count == 1)
    }
}

@MainActor
private final class RecordingSaveRepository: DocumentRepositoryProtocol {
    var snapshots: [MultiPageDocument] = []
    var paths: [URL] = []
    func save(_ document: MultiPageDocument, at path: URL) async throws {
        snapshots.append(document)
        paths.append(path)
    }
    func load(_ note: Note) async throws -> MultiPageDocument { .empty }
}
