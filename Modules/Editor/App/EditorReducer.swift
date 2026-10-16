import Foundation
import PaperKit

extension EditorFeature {
    func reduce(_ state: inout State, _ action: Action) {
        // Freeze document content and navigation requests for the captured save snapshot.
        if state.isSaving {
            switch action {
            case .openNote, .openQuickNote, .retryLoad, .documentLoaded, .documentLoadFailed,
                 .addPageTapped, .pageAppended, .insertPageTapped, .pageInserted,
                 .movePage, .copyPage, .pastePageTapped, .pagePasted,
                 .canvasChanged, .captureMarkups, .pageBackgroundChanged:
                return
            default: break
            }
        }

        switch action {
        case let .openNote(note), let .openQuickNote(note):
            state.note = note
            state.document = nil
            state.copiedPage = nil
            if case .openQuickNote = action { state.mode = .focus } else { state.mode = .write }
            state.loadFailure = nil
            state.saveFailure = nil
            state.hasUnsavedChanges = false
            state.isLoading = true
            state.tools = state.defaultTools
            state.selectedTool = state.defaultTools.first!
            state.previousInkTool = state.defaultTools.first!

        case let .documentLoaded(doc):
            state.document = doc
            state.loadFailure = nil
            state.isLoading = false
            state.hasUnsavedChanges = false
        case let .documentLoadFailed(failure):
            state.document = nil
            state.copiedPage = nil
            state.loadFailure = failure
            state.isLoading = false
            state.hasUnsavedChanges = false
        case .retryLoad:
            guard state.note != nil, !state.isLoading else { break }
            state.document = nil
            state.loadFailure = nil
            state.isLoading = true
            state.hasUnsavedChanges = false
        case .dismissLoadFailure:
            state.loadFailure = nil

        case let .canvasChanged(pageID):
            guard state.canEditDocument, state.document?.pages.contains(where: { $0.id == pageID }) == true else { break }
            state.hasUnsavedChanges = true
        case let .captureMarkups(markups):
            guard state.canEditDocument else { break }
            capture(markups, into: &state)
        case let .pageBackgroundChanged(pageID, background):
            guard state.canEditDocument,
                  let index = state.document?.pages.firstIndex(where: { $0.id == pageID }),
                  state.document?.pages[index].background != background else { break }
            state.document?.pages[index].background = background
            state.hasUnsavedChanges = true
        case let .pageAppended(page):
            guard state.canEditDocument else { break }
            state.document?.addPage(page)
            state.hasUnsavedChanges = true
        case let .pageInserted(after: pageID, page: page), let .pagePasted(after: pageID, page: page):
            guard state.canEditDocument, var pages = state.document?.pages else { break }
            let index = pageID.flatMap { id in pages.firstIndex(where: { $0.id == id }).map { $0 + 1 } } ?? pages.endIndex
            pages.insert(page, at: index)
            state.document?.pages = pages
            state.hasUnsavedChanges = true
        case let .movePage(source, destination):
            guard state.canEditDocument, var pages = state.document?.pages,
                  let sourceIndex = pages.firstIndex(where: { $0.id == source }),
                  let destinationIndex = pages.firstIndex(where: { $0.id == destination }),
                  sourceIndex != destinationIndex else { break }
            let page = pages.remove(at: sourceIndex)
            let insertionIndex = sourceIndex < destinationIndex ? destinationIndex - 1 : destinationIndex
            pages.insert(page, at: insertionIndex)
            guard pages.map(\.id) != state.document?.pages.map(\.id) else { break }
            state.document?.pages = pages
            state.hasUnsavedChanges = true
        case let .copyPage(pageID):
            guard state.canEditDocument else { break }
            state.copiedPage = state.document?.pages.first(where: { $0.id == pageID })

        case let .save(markups, requestID):
            guard state.canSave, let note = state.note else { break }
            capture(markups, into: &state)
            guard let document = state.document else { break }
            state.saveFailure = nil
            state.saveRequest = SaveRequest(id: requestID, note: note, document: document)
        case let .saved(requestID):
            guard state.saveRequest?.id == requestID else { break }
            state.saveFailure = nil
            state.saveRequest = nil
            state.hasUnsavedChanges = false
        case let .savedFailed(requestID, failure):
            guard state.saveRequest?.id == requestID else { break }
            state.saveFailure = failure
            state.saveRequest = nil
        case .dismissSaveFailure:
            state.saveFailure = nil

        case .toggleEditMode:
            switch state.mode {
            case .read:
                state.mode = .write
                state.selectedTool = state.tools.first!
            case .write:
                state.mode = .read
            case .focus: break
            }
        case .toggleFocusMode:
            state.mode = toggleFocusMode(state.mode)
        case let .toolSelected(tool):
            state.selectedTool = tool
            if tool != .eraser { state.previousInkTool = tool }
        case .pencilDoubleTap:
            if state.selectedTool == .eraser {
                state.selectedTool = state.previousInkTool
            } else {
                state.previousInkTool = state.selectedTool
                state.selectedTool = .eraser
            }
        case let .defaultToolsChanged(tools):
            state.defaultTools = tools
            state.tools = tools
            state.selectedTool = tools.first!
            state.previousInkTool = tools.first!
        default: break
        }
    }

    private func capture(_ markups: [UUID: PaperMarkup], into state: inout State) {
        guard var document = state.document else { return }
        for index in document.pages.indices {
            if let markup = markups[document.pages[index].id] {
                document.pages[index].markup = markup
            }
        }
        state.document = document
    }

    func toggleFocusMode(_ mode: EditMode) -> EditMode {
        switch mode {
        case .read, .write: .focus
        case .focus: .write
        }
    }
}
