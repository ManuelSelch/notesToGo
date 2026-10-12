# NotesToGo Persistence and File Management — Requirements

## Goal
Make creating, opening, saving, renaming, and moving existing notes reliable and understandable. Preserve handwriting and page structure, prevent silent data loss, and provide actionable errors. Establish the persistence foundation for subsequently saving complete notes as standard PDFs.

## Scope
### In Scope
- Consistent editable-document storage for new, quick, and existing notes.
- Compatibility with the existing multipage JSON sidecars and legacy single-page PaperKit sidecars.
- Explicit load, save, creation, listing, rename, and move error handling.
- Explicit manual saving with unsaved-change tracking, safe save-and-close behavior, and protection against overlapping document operations.
- Preservation of existing handwriting when reopening or resizing the editor.
- Renaming note files and moving them between existing folders inside the app's local Documents directory, with a fast combined rename-and-move workflow for organizing QuickNotes.
- Shared validation and filesystem-operation safeguards reusable for future folder management; folder actions themselves are excluded.
- Treating a PDF and its optional hidden `.markup` sidecar as one logical note.
- Real-filesystem tests, failure injection, editor-state tests, and focused UI flows.

### Out of Scope
- Rendering handwriting and backgrounds into the PDF; the PDF remains unchanged by editor saves in this phase.
- PDF-only editable storage, imported-PDF rendering improvements, or a new sync provider.
- External folders, Files-provider integration, WebDAV, and cross-device conflict resolution.
- Folder rename/move, deleting notes, bulk operations, and drag-and-drop unless separately agreed.
- Automatic timed, change-triggered, background, or page-grid-transition saves. Only explicit Save and save-and-close write editor changes.
- Unrelated app architecture refactoring or dependency upgrades, except changes needed to restore test execution.

## Requirements
- **R1 — One storage contract:** Note creation and saving use the same document serializer and loader. Newly created notes reopen without an intervening editor save. The new format identifies its version; existing unversioned multipage JSON remains readable. Unsupported versions fail explicitly rather than being interpreted as another format.
- **R2 — Compatible loading:** Load supported multipage JSON and legacy raw PaperKit data without dropping strokes, page order, dimensions, or backgrounds. Legacy single-page data becomes a one-page document with an explicitly documented default background because the legacy file contains no background metadata. Migration preserves the original until a replacement has been successfully written.
- **R3 — Distinguish missing from damaged:** A PDF with no sidecar can initialize an editable document from its actual page geometry. An existing unreadable or corrupt sidecar must not silently become a blank document. Failed loads do not enable editing or saving of a replacement document; retry and returning to the explorer are available.
- **R4 — Correct paths:** Use the actual PDF and sidecar URLs associated with the note, rather than reconstructing a lowercase `.pdf` path. PDF-only notes with uppercase or mixed-case extensions remain loadable and manageable.
- **R5 — Safe creation and saving:** Validate filenames, check PDF-writing success, use atomic replacement for individual files, and preserve the last successful document when serialization or writing fails. Creation must not overwrite an existing PDF or sidecar. A partially failed creation must not be presented as a successfully created note; retained temporary artifacts must be identifiable and recoverable or safely removable.
- **R6 — Visible operation state:** Editor and explorer operations expose appropriate pending, success, and failure state. Failures clear busy indicators, show an actionable message, retain user input or unsaved work, and permit retry. A listing error is not displayed as an empty folder; keep the previous list where available. Expected errors must not disappear through `try?`.
- **R7 — Save before leaving:** Capture current canvas markups and page structure before saving. Close the editor only after the requested save succeeds; on failure, stay in the editor with changes intact. Opening the page grid captures the current canvas into the in-memory document without saving to disk; changes remain unsaved until explicit Save or save-and-close. Closing an already clean document does not require another write. Explicitly discarding work, if offered, requires confirmation.
- **R8 — Serialize operations:** Prevent repeated or overlapping save, close, rename, and move requests from racing. A delayed result from a previously opened note must not update another note's state or write its contents to another note's URLs. Disable mutations during initial loading and capture the intended note and document snapshot for each operation.
- **R9 — Preserve page geometry:** Persist logical document coordinates, not the current screen size. Reopening on another device width or rotating must not replace existing markup with an empty canvas or cumulatively rescale persisted strokes. Round trips preserve page count, order, IDs, bounds, backgrounds, and visible content.
- **R10 — Rename notes:** Rename the PDF and any existing sidecar together, preserving all contents. The user edits a note's base name; extensions and hidden sidecar naming remain app-managed. Reject empty names, path separators, traversal names, and conflicting target files. A same-name request is a no-op; case-only renames work on the supported filesystem or produce a clear error without changing the original.
- **R11 — Move notes:** Move the PDF and any existing sidecar together to an existing folder within the storage root, including the root itself. PDF-only notes are supported; no empty sidecar is invented during rename/move. Moving to the current folder is a no-op. Reject a collision with either destination file and never overwrite silently.
- **R12 — Recoverable paired operations:** Filesystem operations on two files are not assumed to be atomic. If the second rename/move step fails, restore the original pair where possible. If rollback also fails or the operation is interrupted, preserve original data and record enough information to recover a consistent pair on the next launch. Do not report success or continue writing to an ambiguous location.
- **R13 — Refresh references:** Successful rename/move returns the updated note URLs, refreshes affected explorer lists, and invalidates or updates any cached editor reference. File-management operations start from the explorer only when that note is not open or saving, preventing stale paths from recreating files at the old location.
- **R14 — Fast file management:** Existing note cards expose Rename and Move actions directly, without opening the editor or a settings screen. Rename prefills and selects the current base name for immediate typing. QuickNotes also offer one Organize action combining an optional rename and destination-folder selection into one confirmation, rather than two separate workflows. Organizing moves the same note out of QuickNotes; it does not copy or recreate it or use a different document format. Move presents a navigable local folder picker showing the current location. Cancel makes no filesystem changes. Keep the current selection/input and picker open on failure; refresh the explorer after success. Rename/move operate on existing files without reserializing drawings or regenerating the PDF. Use shared name/path validation and recoverable filesystem operations that can later support folders, without implementing folder actions now. Approve an isolated UI mockup before production UI implementation.
- **R15 — Verification:** Add production-repository tests using temporary directories, legacy fixtures, distinguishable nonempty markup, and injected filesystem failures. Cover format compatibility, PDF-only notes, uppercase extensions, corrupt data, failed saves, collision handling, paired-operation rollback/recovery, and reopen after rename/move. UI tests cover manual Save enabled/disabled state, successful save-and-close, visible errors with retry, rename, move, combined QuickNotes organization, and cancel. All implementation slices add their corresponding tests rather than deferring testing to the end.
- **R16 — Manual Save and unsaved changes:** Show a manual Save button in the editor, enabled only when a successfully loaded document has unsaved changes and no conflicting operation is in progress. Opening a note starts clean. Drawing or editing markup and adding, inserting, copying/pasting, reordering, or changing page backgrounds mark the document dirty when they change document content; navigation, tool selection, display resizing, and copying a page without pasting do not. Successful saving clears only the changes included in its snapshot; failed saving retains dirty state and enables retry. Block editing during a save or track subsequent edits separately so a completion cannot incorrectly clear newer changes. Saving does not close the editor. Returning from the grid retains dirty state and reflects page changes in the Save button. No automatic saves are scheduled.

## Assumptions
- The existing PDF plus hidden editable sidecar structure remains in place for this phase; this does not decide the final PDF-export storage design.
- “Existing Files” means note PDFs shown by the current explorer. Files-only management and no automatic saving are confirmed decisions, specified above.
- Explicit create/rename/move collisions are rejected with a message; date-based quick-note creation may retain its current automatic unique-name behavior.
- Note management is initially available only in the explorer, not while editing a note. Fast QuickNotes organization is provided there; editor-level organization can be considered later.
- No existing user data may be discarded merely because its format is old or a load fails.
- The previous build attempt failed in the navigation dependency's `AssociationMacro`. Recheck the current checkout before implementation; runtime verification requires a working build.

## Implementation Plan
### 1. Unified Document Creation and Storage
Description: Establish one shared storage contract for creation and save, with a format version and unversioned-JSON compatibility. Keep actual note URLs together, validate new names, check PDF-write results, and prevent overwriting either member of a note pair. Stage creation and clean up or recover incomplete output. Verify through real-filesystem create/open round trips, uppercase PDF-path tests, duplicate-name tests, and failures while writing either file. This is the prerequisite for later slices; it does not render handwriting into PDFs.

### 2. Compatible Loading and Explicit Errors
Description: Add narrowly identified legacy raw-PaperKit loading and preserve the legacy source during migration. Distinguish missing sidecars, corrupt files, unsupported versions, missing PDFs, and I/O failures. Replace silent empty-document and empty-folder fallbacks with error states and retry/return actions in editor and explorer; failed loads cannot be saved as blank replacements. Verify supported-format fixtures, PDF-only notes, corrupt data, listing failure, and failed migration without source loss. Depends on slice 1.

### 3. Unsaved Changes and Manual Save
Description: Track document-content changes across the canvas and page grid, independently of tool or layout changes. Add a manual Save button, disabled while clean, loading, or saving; save stays in the editor, clears only successfully persisted changes, and retains unsaved work on failure. Approve an isolated Save-button/status mockup before production UI changes. Verify dirty transitions for handwriting and page edits, clean opens, repeated requests, failed saves with retry, and changes made during an in-flight save if editing remains enabled. Depends on slices 1–2; automatic saving is excluded.

### 4. Reliable Save and Navigation Lifecycle
Description: Capture the intended note and current canvas/document snapshot, serialize document operations, and dismiss a dirty document only after an explicitly requested save-and-close succeeds. Close clean documents without a redundant write. Preserve unsaved changes and reset operation state on failure; support retry and ignore stale completions from another note. Capture the canvas before opening the page grid without writing to disk, and preserve dirty state across the round trip. Verify save/close success and failure, rapid repeated taps, reordered completion, grid changes without automatic writes, and retry without losing changes. Depends on slices 1–3.

### 5. Stable Page Geometry and Drawing Round Trips
Description: Separate persisted page coordinates from display layout so opening at another width does not construct empty markup and rotation does not permanently rescale the document. Verify a nonempty drawing survives save/reopen at different sizes, repeated rotation, and page insertion/copy/reordering, while retaining page metadata and bounds. Depends on slices 1–4 and is required before accepting persistence as reliable. Display-only changes must not mark a document dirty.

### 6. Safe Note Rename
Description: Implement note-level rename in the storage layer, returning updated URLs and handling PDF-only notes, invalid names, collisions, same-name requests, and case-only renames. Introduce shared validation and paired-operation rollback/recovery safeguards reusable by moving and future folder operations, and prevent renaming an open or saving note. Rename existing files without reserializing their contents. Verify byte/content preservation, updated paths, reopen under the new name, failure at each filesystem step, rollback failure, and restart recovery. Depends on slices 1–4; UI is deferred to slice 8.

### 7. Safe Note Move and QuickNotes Organization
Description: Reuse slice 6's paired-operation safeguards to move a note to an existing folder inside the storage root, optionally changing its name as part of the same recoverable operation. Validate the final name, destination containment, and collisions; update note references and prevent stale saves to old paths. Move existing files directly without rendering or serializing them. Verify root/nested-folder moves, QuickNotes-to-folder organization with and without renaming, PDF-only notes, same-folder no-ops, invalid or missing destinations, reopen after moving, injected second-file failure, and interrupted-operation recovery. Depends on slices 4 and 6; external storage and folder moves remain excluded.

### 8. Fast Explorer Organization Workflows
Description: Prepare an isolated mockup of directly accessible note actions, a prefilled/select-all rename dialog, and a local folder picker with a combined QuickNotes Organize flow requiring one confirmation. Obtain explicit approval before changing production UI. Wire the approved workflows into explorer state and middleware, including busy/error/retry states, updated lists, and cancellation without changes. Verify UI flows for immediate rename, move to a nested folder and back to root, combined QuickNotes rename/move without opening the editor, collision errors, cancellation, and opening the relocated note. Depends on slices 2, 6, and 7; add accessibility identifiers and extend the existing UI-test DSL.

## Open Questions
None.
