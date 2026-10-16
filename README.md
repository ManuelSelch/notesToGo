# NotesToGo

- **NotesToGo** is a lightweight iOS notes app built with `SwiftUI`, focused on fast, distraction-free note-taking directly on PDFs.
- The app is designed around speed, smooth interactions, and core functionality

## Module Structure

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

## Features

- Write notes directly on PDFs
  - Annotate existing PDFs or add new pages
  - Optimized for handwriting and quick sketches

- Fast note-taking workflow
  - Shortcuts for adding new pages
  - Quick access to commonly used pen tools
  - Minimal UI designed to keep you focused

- Customizable pen tools
  - Multiple pen types
  - Adjustable colors, thickness, and styles
  - Easy switching between tools while writing

- Sync & Storage
  - Sync notes with external providers
  - Option to use your own server
  - `WebDAV` is currently implemented
  - Architecture prepared for additional providers in the future

- Temporary Notes (Planned)
  - Create quick, unorganized notes
  - Temporary notes are automatically archived after a few days
  - Helps keep your workspace clean if notes aren’t organized in time

- Design Goals
  - Speed first – open the app and start writing immediately
  - Smooth interactions – no lag, no unnecessary steps
  - Core features only – avoid complexity and feature overload
  - PDF-centric – notes can the opened & edited by any pdf viewer

- Tech Stack
  - `SwiftUI`
  - Native iOS frameworks for drawing and PDF handling
  - Modular sync layer (currently WebDAV)
