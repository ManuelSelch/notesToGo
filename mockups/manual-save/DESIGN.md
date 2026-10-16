# Manual Save — revision 2

Status: **approved**, revision 2.

## Goal and scope
Add minimal icon-only Save to the existing iPad editor without redesigning its drawing toolbar. HTML approximates SwiftUI/iPad appearance; it does not prove native toolbar layout or PaperKit behavior.

## Proposed design
- Preserve existing Back, pen palette, and editing controls. Place an icon-only **Save** button next to Back (down arrow into a tray; native implementation can use the matching SF Symbol).
- Clean: disabled Save icon. Dirty: enabled blue Save icon. Saving: replace icon with a spinner in the same button footprint, disable Save, editing and navigation. No visible Save text or saved/unsaved status labels. Keep accessible Save/Saving labels.
- Failure: keep content, show existing-style Retry / Keep changes alert; Keep changes returns to enabled Save.
- Save never leaves the editor. No autosave or transient success toast.
- Opening: Save disabled, opening indicator, mutations disabled.
- Tool selection and read/focus switches do not mark the document dirty.
- Preserve existing minimal focus-mode toolbar: exit focus to reach Save. This is a proposed choice for approval, not a production change.
- Target full-size iPad portrait and landscape; desktop browser frame is illustrative. No iPhone design scope.

## Review interactions
- Tap paper to simulate a stroke; tap + or grid to simulate a structural page edit.
- Select next-save outcome to exercise success or failure. Save takes 1.5 seconds and blocks edits. Retry follows the selected outcome.
- State URLs: `?state=clean`, `dirty`, `saving`, `error`, `loading`. Direct saving/loading states remain visible for review until another state is selected; saving initiated with Save completes automatically.
- Reset restores the fake note. Local state only: no file writes, network, browser persistence, or real PDF rendering.

## Omitted / limitations
No real handwriting, actual grid, storage, navigation, or geometry handling. Back/close lifecycle is slice 4; the Back action only explains this boundary. Error text is representative, not an exhaustive error mapping. Production containers must only wire state/actions/routing; reusable components own rendering.

## Open design decision
Approve icon-only Save placement and behavior, including accessing Save by exiting focus mode, or request revision.

## Approval
User approved revision 2 by answering “yes” to “Approve revision 2 for implementation?” and asked how implementation/testing will be structured. Approved scope: icon-only Save, disabled when clean/loading/saving, spinner while saving, no visible status labels. Production implementation has not started.
