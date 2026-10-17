import FactoryKit
import FactoryTesting
import Foundation
import Testing

@testable import notesToGo

@Suite(.container)
@MainActor
struct OperationFailureTests {
    @Test
    func openingMissingNoteReturnsAnErrorInsteadOfEmptyDocument() async {
        let note = missingNote()
        Container.shared.documentRepository.register { InMemoryDocumentRepository() }
        let result = await DocumentMiddleware().handle(state: .init(), action: .openNote(note))

        #expect(result != nil)
        #expect(result != .documentLoaded(.empty))
    }

    @Test
    func listingFailureDoesNotReturnAnEmptySuccess() async {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let result = await ExplorerMiddleware(explorer: ExplorerService(repository: ExplorerRepository())).handle(state: .init(), action: .reloadDocs(missing))

        #expect(result != nil)
        #expect(result != .docsLoaded([]))
    }

    @Test
    func creationFailureReturnsAnActionInsteadOfSilentlyDoingNothing() async {
        var state = ExplorerFeature.State()
        state.newItemName = "../Invalid"
        let result = await ExplorerMiddleware(explorer: ExplorerService(repository: ExplorerRepository())).handle(state: state, action: .createNoteTapped(nil))

        #expect(result != nil)
        #expect(state.newItemName == "../Invalid")
    }

    @Test
    func saveFailureStopsBusyStateAndPreservesDocument() {
        var state = EditorFeature.State()
        state.document = .empty
        state.note = missingNote()
        state.hasUnsavedChanges = true
        let id = UUID()
        EditorFeature().reduce(&state, .save([:], requestID: id))
        let original = state.document

        EditorFeature().reduce(&state, .savedFailed(id, OperationFailure(CocoaError(.fileWriteUnknown))))

        #expect(!state.isSaving)
        #expect(state.document == original)
    }

    @Test
    func loadFailureLeavesNoSaveableReplacementAndCanBeRetried() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let note = try await ExplorerService(repository: ExplorerRepository()).addNote(at: folder, name: "Retry")
        let goodData = try Data(contentsOf: note.markup)
        let damagedData = Data("Damaged editable data".utf8)
        try damagedData.write(to: note.markup)
        var state = EditorFeature.State()
        let feature = EditorFeature()
        let middleware = DocumentMiddleware()
        feature.reduce(&state, .openNote(note))

        let failed = try #require(await middleware.handle(state: state, action: .retryLoad))
        #expect(failed == .documentLoadFailed(OperationFailure(EditorError.corruptDocument)))
        feature.reduce(&state, failed)
        #expect(state.document == nil)
        #expect(!state.isLoading)
        #expect(state.loadFailure != nil)
        feature.reduce(&state, .save([:]))
        #expect(await middleware.handle(state: state, action: .save([:])) == nil)
        #expect(try Data(contentsOf: note.markup) == damagedData)

        try goodData.write(to: note.markup)
        feature.reduce(&state, .retryLoad)
        #expect(state.isLoading)
        #expect(state.loadFailure == nil)
        let loaded = try #require(await middleware.handle(state: state, action: .retryLoad))
        feature.reduce(&state, loaded)
        #expect(state.document?.pages.count == 1)
        #expect(!state.isLoading)
    }

    @Test
    func listingFailurePreservesPreviousListAndRetryCanSucceed() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let previous = [Document.note(missingNote())]
        var state = ExplorerFeature.State()
        state.docs = previous
        let feature = ExplorerFeature()
        let middleware = ExplorerMiddleware(explorer: ExplorerService(repository: ExplorerRepository()))
        feature.reduce(&state, .reloadDocs(folder))
        let failure = try #require(await middleware.handle(state: state, action: .reloadDocs(folder)))
        feature.reduce(&state, failure)

        #expect(state.docs == previous)
        #expect(state.failure != nil)
        #expect(!state.isLoading)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        feature.reduce(&state, .retryOperation)
        let success = try #require(await middleware.handle(state: state, action: .retryOperation))
        #expect(success == .docsLoaded([]))
        feature.reduce(&state, success)
        #expect(state.docs.isEmpty)
        #expect(state.failure == nil)
        #expect(!state.isLoading)
    }

    @Test
    func creationFailurePreservesNameAndRetryUsesCorrectedInput() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        var state = ExplorerFeature.State()
        state.newItemName = "../Invalid"
        let feature = ExplorerFeature()
        let middleware = ExplorerMiddleware(explorer: ExplorerService(repository: ExplorerRepository()))
        feature.reduce(&state, .createNoteTapped(folder))
        let failure = try #require(await middleware.handle(state: state, action: .createNoteTapped(folder)))
        feature.reduce(&state, failure)

        #expect(state.failure == OperationFailure(EditorError.invalidNoteName))
        #expect(state.newItemName == "../Invalid")
        #expect(state.pendingDestination == nil)
        #expect(!state.isLoading)
        feature.reduce(&state, .newItemNameChanged("Corrected"))
        feature.reduce(&state, .retryOperation)
        let success = try #require(await middleware.handle(state: state, action: .retryOperation))
        feature.reduce(&state, success)
        #expect(state.failure == nil)
        #expect(!state.isLoading)
        #expect(state.newItemName.isEmpty)
        guard case let .note(note) = state.pendingDestination else {
            Issue.record("Successful creation should navigate to the created note")
            return
        }
        #expect(note.pdf.lastPathComponent == "Corrected.pdf")
    }

    @Test
    func quickNoteCreationFailureIsActionable() async {
        var state = ExplorerFeature.State()
        ExplorerFeature().reduce(&state, .createQuickNoteTapped)
        let repository = ExplorerRepositoryStub()
        repository.failure = CocoaError(.fileWriteNoPermission)
        let result = await ExplorerMiddleware(explorer: ExplorerService(repository: repository)).handle(state: state, action: .createQuickNoteTapped)

        #expect(result == .operationFailed(OperationFailure(CocoaError(.fileWriteNoPermission))))
    }

    @Test
    func invalidFolderNameDoesNotEscapeStorageRoot() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var state = ExplorerFeature.State()
        state.newItemName = "../Escape"
        let result = await ExplorerMiddleware(explorer: ExplorerService(repository: ExplorerRepository())).handle(state: state, action: .createFolderTapped(folder))

        #expect(result == .operationFailed(OperationFailure(EditorError.invalidNoteName)))
        #expect(!FileManager.default.fileExists(atPath: folder.path))
    }

    @Test
    func saveFailurePreservesSnapshotAndRetryClearsErrorOnSuccess() async throws {
        let repository = RetryableSaveRepository()
        Container.shared.documentRepository.register { repository }
        let middleware = DocumentMiddleware()
        let feature = EditorFeature()
        var state = EditorFeature.State()
        state.note = missingNote()
        state.document = .empty
        state.hasUnsavedChanges = true
        let original = state.document
        let first = EditorFeature.Action.save([:])
        feature.reduce(&state, first)
        let failed = try #require(await middleware.handle(state: state, action: first))
        feature.reduce(&state, failed)

        #expect(state.saveFailure == OperationFailure(CocoaError(.fileWriteNoPermission)))
        #expect(state.document == original)
        #expect(!state.isSaving)
        #expect(state.hasUnsavedChanges)
        repository.shouldFail = false
        let retryID = UUID()
        let retry = EditorFeature.Action.save([:], requestID: retryID)
        feature.reduce(&state, retry)
        let saved = try #require(await middleware.handle(state: state, action: retry))
        #expect(saved == .saved(retryID))
        feature.reduce(&state, saved)
        #expect(state.saveFailure == nil)
        #expect(!state.isSaving)
        #expect(!state.hasUnsavedChanges)
    }

    private func missingNote() -> Note {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return Note(pdf: folder.appendingPathComponent("Missing.pdf"), markup: folder.appendingPathComponent(".Missing.markup"))
    }
}

@MainActor
private final class RetryableSaveRepository: DocumentRepositoryProtocol {
    var shouldFail = true

    func save(_ document: MultiPageDocument, at path: URL) async throws {
        if shouldFail { throw CocoaError(.fileWriteNoPermission) }
    }

    func load(_ note: Note) async throws -> MultiPageDocument { .empty }
}
