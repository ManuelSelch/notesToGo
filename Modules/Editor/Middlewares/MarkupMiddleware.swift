import Foundation
import Flux

class MarkupMiddleware {
    
    func handle(state: EditorFeature.State, action: EditorFeature.Action) async -> EditorFeature.Action? {
        
        return .none
    }
}
