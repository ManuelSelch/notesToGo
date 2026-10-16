import FactoryKit
import Router

@MainActor
extension Container {
    var router: Factory<MyRouter> {
        self { MyRouter(root: .explorer(.dashboard(path: nil))) }.cached
    }

    var documentRepository: Factory<DocumentRepositoryProtocol> {
        self { DocumentRepository() }.cached
    }
}
