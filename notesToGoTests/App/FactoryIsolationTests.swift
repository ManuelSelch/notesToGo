import FactoryKit
import FactoryTesting
import Foundation
import Router
import Testing
@testable import notesToGo

extension AppModuleTests {
    @Suite(.container)
    @MainActor
    struct FactoryIsolationTests {
        @Test(arguments: 0..<8)
        func parameterizedCasesHaveFreshContainersAcrossSuspension(index: Int) async throws {
            let container = Container.shared
            #expect(container.documentRepository() is DocumentRepository)
            #expect(container.router().stack.stack.isEmpty)
            let repository = InMemoryDocumentRepository()
            container.documentRepository.register { repository }
            let note = sharedNote()
            let document = MultiPageDocument(pages: (0...index).map { _ in Page.empty(id: UUID()) })
            try await repository.save(document, at: note.markup)
            let middleware = DocumentMiddleware()

            await Task.yield()
            let result = await middleware.handle(state: .init(), action: .openNote(note))

            #expect(Container.shared === container)
            #expect(Container.shared.documentRepository() as AnyObject === repository)
            #expect(result == .documentLoaded(document))
            #expect(container.router().stack.stack == [.editor(.editor)])
        }

        @Test(.timeLimit(.minutes(1)))
        func overlappingScopesKeepServicesIsolatedUntilChildTasksFinish() async throws {
            let parent = Container.shared
            let parentRepository = parent.documentRepository() as AnyObject
            let parentRouter = parent.router()
            let rendezvous = SaveRendezvous()
            let note = sharedNote()

            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<2 {
                    group.addTask {
                        try await exerciseScope(Container(), note: note, rendezvous: rendezvous)
                    }
                }
                // Observe the first thrown error promptly and cancel/drain its sibling.
                for try await _ in group {}
            }

            #expect(Container.shared === parent)
            #expect(parent.documentRepository() as AnyObject === parentRepository)
            #expect(parentRouter.stack.stack.isEmpty)
        }

        private func exerciseScope(_ container: Container, note: Note, rendezvous: SaveRendezvous) async throws {
            try await Container.$shared.withValue(container) {
                let repository = SuspendedSaveRepository(rendezvous: rendezvous)
                container.documentRepository.register { repository }
                container.router.register { MyRouter(root: .explorer(.dashboard(path: nil))) }
                let router = container.router()
                let middleware = DocumentMiddleware()
                let document = MultiPageDocument(template: .empty)
                let feature = EditorFeature()
                var state = EditorFeature.State()
                state.note = note
                state.document = document
                state.hasUnsavedChanges = true
                let requestID = UUID()
                let save = EditorFeature.Action.save([:], requestID: requestID)
                feature.reduce(&state, save)
                let savingState = state

                // Match Flux's Task-based dispatch, but retain and await the child task.
                let task = Task {
                    #expect(Container.shared === container)
                    return await middleware.handle(state: savingState, action: save)
                }
                let result = await withTaskCancellationHandler {
                    await task.value
                } onCancel: {
                    task.cancel()
                }
                try Task.checkCancellation()
                let completion = try #require(result)
                #expect(completion == .saved(requestID))
                feature.reduce(&state, completion)
                #expect(!state.hasUnsavedChanges)
                #expect(!state.isSaving)
                #expect(repository.savedDocuments == [document])
                #expect(middleware.repo as AnyObject === repository)
                #expect(middleware.router === router)

                let loaded = await middleware.handle(state: state, action: .openNote(note))
                #expect(loaded == .documentLoaded(document))
                #expect(Container.shared === container)
                #expect(container.documentRepository() as AnyObject === repository)
                #expect(router.stack.stack == [.editor(.editor)])
            }
        }

        /// Both scopes deliberately use the same URL; isolation must come from services, not paths.
        private func sharedNote() -> Note {
            let folder = URL(fileURLWithPath: "/FactoryIsolationTests")
            return Note(pdf: folder.appendingPathComponent("Shared.pdf"), markup: folder.appendingPathComponent(".Shared.markup"))
        }
    }
}

/// One-shot barrier: neither save can complete until both scopes have started saving.
private actor SaveRendezvous {
    private var waiters: [AsyncStream<Void>.Continuation] = []

    func arrive() async throws {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        waiters.append(continuation)
        if waiters.count == 2 {
            for waiter in waiters { waiter.finish() }
            waiters.removeAll()
        }
        // AsyncStream iteration also terminates on cancellation, so a failed sibling
        // or test timeout cannot strand a checked continuation or block the main actor.
        for await _ in stream {}
        try Task.checkCancellation()
    }
}

@MainActor
private final class SuspendedSaveRepository: DocumentRepositoryProtocol {
    private let rendezvous: SaveRendezvous
    private var documents: [URL: MultiPageDocument] = [:]
    private(set) var savedDocuments: [MultiPageDocument] = []

    init(rendezvous: SaveRendezvous) { self.rendezvous = rendezvous }

    func save(_ document: MultiPageDocument, at path: URL) async throws {
        await Task.yield()
        try await rendezvous.arrive()
        documents[path] = document
        savedDocuments.append(document)
    }

    func load(_ note: Note) async throws -> MultiPageDocument {
        guard let document = documents[note.markup] else { throw EditorError.documentNotFound }
        return document
    }
}
