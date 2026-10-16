import Flux

/// Module entry point and dependency wiring.
struct ExplorerApp {
    func build() -> FluxStore<ExplorerFeature> {
        let repository = ExplorerRepository()
        let service = ExplorerService(repository: repository)
        return .init(
            state: .init(),
            middlewares: [
                ExplorerMiddleware(explorer: service).handle,
                LogMiddleware<ExplorerFeature>().handle
            ]
        )
    }
}
