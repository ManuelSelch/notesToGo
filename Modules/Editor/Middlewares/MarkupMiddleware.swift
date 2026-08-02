import Foundation
import Flux
import Combine

class MarkupMiddleware {
    let editor: EditorConfig
    private var cancellables: Set<AnyCancellable> = []
    
    init(editor: EditorConfig) {
        self.editor = editor
    }
    
    func start(_ store: FluxStore<EditorFeature>) {
        editor.$penSize
            .removeDuplicates()
            .sink { store.dispatch(.penSizeLoaded($0)) }
            .store(in: &cancellables)
    }
    
    func stop() {
        cancellables.removeAll()
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
