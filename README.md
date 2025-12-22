# NotesToGo

- **NotesToGo** is a lightweight iOS notes app built with `SwiftUI`, focused on fast, distraction-free note-taking directly on PDFs.
- The app is designed around speed, smooth interactions, and core functionality

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
