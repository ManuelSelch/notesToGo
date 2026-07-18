import Foundation
import Flux
import PaperKit

nonisolated struct EditorFeature: Feature {
    struct State: Equatable, Sendable {
        var note: Note?
        var document: MultiPageDocument?
        
        var isLoading = false
        var mode: EditMode = .read
        var selectedTool: PencilTool = .pen
        var previousInkTool: PencilTool = .pen
        var copiedPage: Page?
    }
    
    enum Action: Equatable, Sendable {
        // MARK: - document
        case openNote(Note)
        case openQuickNote(Note)
        case documentLoaded(MultiPageDocument)
        case addPageTapped
        case insertPage(after: UUID?)
        case movePage(source: UUID, destination: UUID)
        case copyPage(UUID)
        case pastePage(after: UUID?)
        
        // MARK: - save
        case save([UUID:PaperMarkup])
        case saved
        case savedFailed
        
        // MARK: - mode
        case toggleEditMode
        case toggleFocusMode
        
        // MARK: - tool
        case toolSelected(PencilTool)
        case pencilDoubleTap
    }
    
    enum Route: RouteType {
        /// main editor screen to read & write
        case editor
        
        /// page grid to rearrange, copy, and insert pages
        case grid
        
        var id: Self { self }
    }
    
    init() {}
    
    func reduce(_ state: inout State, _ action: Action) {
        switch action {
        // MARK: - document
        case let .openNote(note):
            state.note = note
            state.mode = .write
            state.selectedTool = .pen
            state.isLoading = true
        case let .openQuickNote(note):
            state.note = note
            state.mode = .focus
            state.selectedTool = .pen
            state.isLoading = true
            
        case let .documentLoaded(doc):
            state.document = doc
            state.isLoading = false
        case .addPageTapped:
            state.document?.addPage(.empty)
        case let .insertPage(after: pageID):
            guard var pages = state.document?.pages else { break }
            let index = pageID.flatMap { id in pages.firstIndex(where: { $0.id == id }).map { $0 + 1 } } ?? pages.endIndex
            pages.insert(.empty, at: index)
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
        case let .pastePage(after: pageID):
            guard let copiedPage = state.copiedPage else { break }
            guard var pages = state.document?.pages else { break }
            let page = copiedPage.duplicated()
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
                state.selectedTool = .pen // auto select pen when toggling from read to write mode
            case .write:
                state.mode = .read
            case .focus:
                break
            }
        case .toggleFocusMode:
            state.mode = toggleFocusMode(state.mode)
            
        // MARK: - tool
        case let .toolSelected(tool):
            state.selectedTool = tool
            if tool != .eraser {
                state.previousInkTool = tool
            }
        case .pencilDoubleTap:
            state.selectedTool = state.selectedTool == .eraser ? state.previousInkTool : .eraser
            
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
