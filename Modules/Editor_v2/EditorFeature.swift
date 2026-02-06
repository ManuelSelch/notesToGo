import Foundation
import Flux

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
    
        case save
        case saved
        case savedFailed
        
        // MARK: - toggle edit mode
        case toggleEditMode
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
            
        case .save:
            state.isLoading = true
            
        case .saved:
            state.isLoading = false
            
        case .toggleEditMode:
            state.mode = toggleReadWriteMode(state.mode)
            
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
