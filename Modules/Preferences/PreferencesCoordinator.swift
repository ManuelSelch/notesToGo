import Foundation
import Flux

class PreferencesCoordinator {
    
    init() {
        
    }
    
    func statusBarHidden(_ editor: FluxStore<EditorFeature>) -> Bool {
        return editor.state.mode == .focus
    }
}
