import FactoryKit
import FactoryTesting
import Router
import Testing
@testable import notesToGo

extension AppModuleTests {
    @Suite(.container)
    @MainActor
    struct FactoryRegistrationTests {
        @Test func routerIsCachedAndStartsAtExplorerDashboard() {
            let container = Container.shared
            let router = container.router()

            #expect(container.router() === router)
            #expect(router.stack.root == .explorer(.dashboard(path: nil)))
        }

        @Test func realDocumentRepositoryIsCached() throws {
            let container = Container.shared
            let repository = try #require(container.documentRepository() as? DocumentRepository)

            #expect((container.documentRepository() as? DocumentRepository) === repository)
        }

        @Test func separateContainersHaveIndependentRouters() {
            let first = Container.shared.router()
            let secondContainer = Container()
            let second = secondContainer.router()

            #expect(first !== second)
            #expect(secondContainer.router() === second)
        }

        @Test func separateContainersHaveIndependentRepositories() throws {
            let first = try #require(Container.shared.documentRepository() as? DocumentRepository)
            let secondContainer = Container()
            let second = try #require(secondContainer.documentRepository() as? DocumentRepository)

            #expect(first !== second)
            #expect((secondContainer.documentRepository() as? DocumentRepository) === second)
        }

        @Test func containerRetainsServicesWithoutConsumers() {
            let container = Container.shared
            weak var router = container.router()
            weak var repository = container.documentRepository() as? DocumentRepository

            #expect(router != nil)
            #expect(repository != nil)
            #expect(container.router() === router)
            #expect((container.documentRepository() as? DocumentRepository) === repository)
        }
    }
}
