# Module Architecture

The Explorer module uses these boundaries:

- Module root: entry point, container, routing, and dependency wiring.
- `App/`: application services, Flux state/reducers, middleware, and storage protocols consumed by use cases.
- `Domain/`: models and pure naming/ordering rules; no filesystem or PDFKit operations.
- `Infra/`: concrete repositories and filesystem/PDF adapters.
- `UI/`: screens and stateless components.

`ExplorerService` coordinates domain rules and an injected `ExplorerRepositoryProtocol`.
`ExplorerRepository` owns staged note-pair creation, publication, and rollback.
Explorer lists folders first, then notes, with natural alphabetical ordering within each group.
Other modules have not yet been reorganized to this layout.
