import Foundation
import Flux
import PaperKit

nonisolated struct EditorFeature: Feature {
    struct State: Equatable, Sendable {
        var path: URL?
        var document: MultiPageDocument?
        
        var isLoading = false
        var mode: EditMode = .read
        var selectedTool: PencilTool = .pen
        var previousInkTool: PencilTool = .pen
    }
    
    enum Action: Equatable, Sendable {
        // MARK: - document
        case open(URL)
        case documentLoaded(MultiPageDocument)
        case addPageTapped
        
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
        case editor(Note)
        
        /// page grid to rearrange or delete them
        case grid
        
        var id: Self { self }
    }
    
    init() {}
    
    func reduce(_ state: inout State, _ action: Action) {
        switch action {
        // MARK: - document
        case let .open(path):
            state.path = path
            state.isLoading = true
        case let .documentLoaded(doc):
            state.document = doc
            state.isLoading = false
        case .addPageTapped:
            state.document?.addPage(.empty)
            
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
