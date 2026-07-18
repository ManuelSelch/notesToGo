import Foundation
import Dependencies
import Flux
import Router

class DocumentMiddleware {
    @Dependency(\.documentRepository) var repo
    @Dependency(\.router) var router
    
    init() {}
    
    func handle(state: EditorFeature.State, action: EditorFeature.Action) async -> EditorFeature.Action? {
        switch(action) {
        case let .openNote(note):
            router.stack.push(.editor(.editor))
            let doc = (try? await repo.load(note.markup)) ?? .empty
            return .documentLoaded(doc)
            
        case let .openQuickNote(note):
            router.stack.push(.editor(.editor))
            let doc = (try? await repo.load(note.markup)) ?? .empty
            return .documentLoaded(doc)
            
        case .save:
            guard let doc = state.document, let path = state.note?.markup else { break }
            
            do {
                try await repo.save(doc, at: path)
                return .saved
            } catch { return .savedFailed }
        
        default: break
        }
        
        return .none
    }
}
