import Foundation

extension EditorFeature {
    func reduce(_ state: inout State, _ action: Action) {
        switch action {
        // MARK: - document
        case let .openNote(note):
            state.note = note
            state.mode = .write
            state.isLoading = true
            state.selectedTool = .pen(state.penSize, state.defaultColor)
            state.previousInkTool = .pen(state.penSize, state.defaultColor)
        case let .openQuickNote(note):
            state.note = note
            state.mode = .focus
            state.isLoading = true
            state.selectedTool = .pen(state.penSize, state.defaultColor)
            state.previousInkTool = .pen(state.penSize, state.defaultColor)
            
        case let .documentLoaded(doc):
            state.document = doc
            state.isLoading = false
        case let .pageAppended(page):
            state.document?.addPage(page)
        case let .pageInserted(after: pageID, page: page):
            guard var pages = state.document?.pages else { break }
            let index = pageID.flatMap { id in pages.firstIndex(where: { $0.id == id }).map { $0 + 1 } } ?? pages.endIndex
            pages.insert(page, at: index)
            state.document?.pages = pages
        case let .movePage(source, destination):
            guard var pages = state.document?.pages,
                  let sourceIndex = pages.firstIndex(where: { $0.id == source }),
                  let destinationIndex = pages.firstIndex(where: { $0.id == destination }),
                  sourceIndex != destinationIndex else { break }
            
            let page = pages.remove(at: sourceIndex)
            let insertionIndex = sourceIndex < destinationIndex ? destinationIndex - 1 : destinationIndex
            pages.insert(page, at: insertionIndex)
            state.document?.pages = pages
        case let .copyPage(pageID):
            state.copiedPage = state.document?.pages.first(where: { $0.id == pageID })
        case let .pagePasted(after: pageID, page: page):
            guard var pages = state.document?.pages else { break }
            let index = pageID.flatMap { id in pages.firstIndex(where: { $0.id == id }).map { $0 + 1 } } ?? pages.endIndex
            pages.insert(page, at: index)
            state.document?.pages = pages
            
        // MARK: - save
        case let .save(markups):
            state.isLoading = true
            
            // sync markups
            for (id, markup) in markups {
                if let index = state.document?.pages.firstIndex(where: { $0.id == id }) {
                    state.document?.pages[index].markup = markup
                }
            }
        case .saved:
            state.isLoading = false
            
        // MARK: - mode
        case .toggleEditMode:
            switch(state.mode) {
            case .read:
                state.mode = .write
                state.selectedTool = .pen(state.penSize, state.defaultColor) // auto select pen when toggling from read to write mode
            case .write:
                state.mode = .read
            case .focus:
                break
            }
        case .toggleFocusMode:
            state.mode = toggleFocusMode(state.mode)
            
        // MARK: - tool
        case let .penSizeChanged(size):
            state.penSize = size
            state.selectedTool = .pen(size, state.defaultColor)
        case let .toolSelected(tool):
            state.selectedTool = tool
            if tool != .eraser {
                state.previousInkTool = tool
            }
        case .pencilDoubleTap:
            if state.selectedTool == .eraser {
                state.selectedTool = state.previousInkTool
            } else {
                state.previousInkTool = state.selectedTool
                state.selectedTool = .eraser
            }
        case let .selectedColorChanged(color):
            state.selectedTool = .pen(state.penSize, color)
        case let .defaultColorChanged(color):
            state.defaultColor = color
            
        default: break
        }
    }
    
    func toggleFocusMode(_ mode: EditMode) -> EditMode {
        return switch(mode) {
        case .read, .write:  .focus
        case .focus: .write
        }
    }
}
