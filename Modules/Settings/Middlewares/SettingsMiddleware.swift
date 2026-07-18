import Foundation
import Flux

class SettingsMiddleware {
    let editor: EditorConfig
    
    init(editor: EditorConfig) {
        self.editor = editor
    }
    
    func handle(state: SettingsFeature.State, action: SettingsFeature.Action) async -> SettingsFeature.Action? {
        switch(action) {
        case let .penSizeChanged(size):
            editor.penSize = size
            break
        default: break
        }
        
        return .none
    }
}
