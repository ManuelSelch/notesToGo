import FactoryKit
import FactoryTesting
import Foundation
import Router
import Testing
@testable import notesToGo

extension AppModuleTests {
    @Suite(.container)
    @MainActor
    struct FactoryConsumerTests {
        @Test func middlewareUsesRegisteredRepositoryAndSharedRouter() async throws {
            let container = Container.shared
            let repository = InMemoryDocumentRepository()
            container.documentRepository.register { repository }
            let router = container.router()
            let note = missingNote()
            let document = MultiPageDocument(template: .empty)
            try await repository.save(document, at: note.markup)
            let middleware = DocumentMiddleware()

            let result = await middleware.handle(state: .init(), action: .openNote(note))

            #expect(result == .documentLoaded(document))
            #expect(middleware.repo as AnyObject === repository)
            #expect(middleware.router === router)
            #expect(router.stack.stack == [.editor(.editor)])
        }

        @Test func middlewareRetainsServicesResolvedAtConstruction() async throws {
            let container = Container.shared
            let first = InMemoryDocumentRepository()
            container.documentRepository.register { first }
            let middleware = DocumentMiddleware()
            let originalRouter = container.router()
            let note = missingNote()
            let document = MultiPageDocument(template: .empty)
            try await first.save(document, at: note.markup)

            let replacement = InMemoryDocumentRepository()
            container.documentRepository.register { replacement }
            container.router.register { MyRouter(root: .explorer(.dashboard(path: nil))) }
            let replacementRouter = container.router()
            let result = await middleware.handle(state: .init(), action: .openNote(note))

            #expect(result == .documentLoaded(document))
            #expect(middleware.repo as AnyObject === first)
            #expect(middleware.router === originalRouter)
            #expect(originalRouter.stack.stack == [.editor(.editor)])
            #expect(replacementRouter.stack.stack.isEmpty)
        }

        @Test func viewContainersResolveTheSameRouterAsMiddleware() {
            let router = Container.shared.router()
            let editor = EditorContainer(.editor)
            let explorer = ExplorerContainer(route: .dashboard(path: nil), openNoteTapped: { _ in }, openQuickNoteTapped: { _ in })
            let settings = SettingsContainer(.settings)

            #expect(editor.router === router)
            #expect(explorer.router === router)
            #expect(settings.router === router)
            #expect(DocumentMiddleware().router === router)
        }

        private func missingNote() -> Note {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            return Note(pdf: folder.appendingPathComponent("Factory.pdf"), markup: folder.appendingPathComponent(".Factory.markup"))
        }
    }
}

#if DEBUG
extension AppModuleTests {
    @Suite(.container)
    @MainActor
    struct UITestRepositoryRegistrationTests {
        @Test(arguments: ["delayed", "failOnce"])
        func identifiedUITestRegistersCachedSaveRepository(mode: String) throws {
            let environment = [
                "NOTESTOGO_UI_TEST_ID": UUID().uuidString,
                "NOTESTOGO_UI_TEST_SAVE_MODE": mode
            ]
            try UITestFixtures.registerEditorRepository(environment: environment)
            let middleware = DocumentMiddleware()

            #expect(!(middleware.repo is DocumentRepository))
            #expect(middleware.repo as AnyObject === Container.shared.documentRepository() as AnyObject)
        }

        @Test(arguments: ["normal", "unidentified", "unsupported", "cleanup"])
        func nonSaveTestLaunchesKeepRealRepository(mode: String) throws {
            var environment: [String: String] = [:]
            if mode != "normal" {
                environment["NOTESTOGO_UI_TEST_SAVE_MODE"] = "failOnce"
            }
            if mode == "unsupported" || mode == "cleanup" {
                environment["NOTESTOGO_UI_TEST_ID"] = UUID().uuidString
            }
            if mode == "unsupported" { environment["NOTESTOGO_UI_TEST_SAVE_MODE"] = "unsupported" }
            if mode == "cleanup" { environment["NOTESTOGO_UI_TEST_MODE"] = "cleanup" }
            let repository = try #require(Container.shared.documentRepository() as? DocumentRepository)

            try UITestFixtures.registerEditorRepository(environment: environment)

            #expect(DocumentMiddleware().repo as AnyObject === repository)
        }

        @Test func malformedTestIDIsRejectedBeforeRegistering() throws {
            let repository = try #require(Container.shared.documentRepository() as? DocumentRepository)
            #expect(throws: (any Error).self) {
                try UITestFixtures.registerEditorRepository(environment: [
                    "NOTESTOGO_UI_TEST_ID": "../Documents",
                    "NOTESTOGO_UI_TEST_SAVE_MODE": "failOnce"
                ])
            }
            #expect(Container.shared.documentRepository() as AnyObject === repository)
        }
    }
}
#endif
