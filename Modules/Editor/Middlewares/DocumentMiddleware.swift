import Foundation
import Dependencies
import Flux

class DocumentMiddleware {
    private var repo: DocumentRepositoryProtocol
    
    init(repo: DocumentRepositoryProtocol) {
        self.repo = repo
    }
    
    func handle(state: EditorFeature.State, action: EditorFeature.Action) async -> EditorFeature.Action? {
        switch(action) {
        case let .open(path):
            let doc = (try? await repo.load(path)) ?? .empty
            return .documentLoaded(doc)
            
        case .save:
            guard let doc = state.document, let path = state.path else { break }
            
            do {
                try await repo.save(doc, at: path)
                return .saved
            } catch { return .savedFailed }
        
        default: break
        }
        
        return .none
    }
}
