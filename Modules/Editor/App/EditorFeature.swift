import Foundation
import Flux
import PaperKit

nonisolated struct EditorFeature: Feature {
    struct State: Equatable, Sendable {
        var path: URL?
        var document: MultiPageDocument?
        
        var isLoading = false
        var mode: EditMode = .read
    }
    
    enum Action: Equatable, Sendable {
        // MARK: - document
        case open(URL)
        case documentLoaded(MultiPageDocument)
    
        case save([UUID:PaperMarkup])
        case saved
        case savedFailed
        
        case addPageTapped
        
        // MARK: - toggle edit mode
        case toggleEditMode
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
            
        case .toggleEditMode:
            state.mode = toggleReadWriteMode(state.mode)
            
        case .addPageTapped:
            state.document?.addPage(.empty)
            
        default: break
        }
    }
    
    func toggleReadWriteMode(_ mode: EditMode) -> EditMode {
        return switch(mode) {
        case .read:  .write
        case .write: .read
        case .focus: .focus
        }
    }
}
