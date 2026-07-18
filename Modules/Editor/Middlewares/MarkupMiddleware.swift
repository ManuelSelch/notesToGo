import Foundation
import Flux

class MarkupMiddleware {
    let editor: EditorConfig
    
    init(editor: EditorConfig) {
        self.editor = editor
    }
    
    func handle(state: EditorFeature.State, action: EditorFeature.Action) async -> EditorFeature.Action? {
        switch(action) {
        case .openNote, .openQuickNote:
            return .penSizeLoaded(editor.penSize)
            
        default: break
        }
        return .none
    }
}
