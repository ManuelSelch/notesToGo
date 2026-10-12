import Foundation
import Dependencies
import Flux
import Router

class DocumentMiddleware {
    @Dependency(\.documentRepository) var repo
    @Dependency(\.router) var router
    
    private let repositoryOverride: DocumentRepositoryProtocol?

    init(repository: DocumentRepositoryProtocol? = nil) {
        repositoryOverride = repository
    }
    
    func handle(state: EditorFeature.State, action: EditorFeature.Action) async -> EditorFeature.Action? {
        let repo = repositoryOverride ?? self.repo
        switch(action) {
        case let .openNote(note), let .openQuickNote(note):
            router.stack.push(.editor(.editor))
            return await load(note, using: repo)
        case .retryLoad:
            guard let note = state.note else { return .none }
            return await load(note, using: repo)
            
        case .save:
            guard let doc = state.document, let path = state.note?.markup else { break }
            
            do {
                try await repo.save(doc, at: path)
                return .saved
            } catch { return .savedFailed(OperationFailure(error)) }
        
        default: break
        }
        
        return .none
    }

    private func load(_ note: Note, using repo: DocumentRepositoryProtocol) async -> EditorFeature.Action {
        do {
            return .documentLoaded(try await repo.load(note))
        } catch {
            return .documentLoadFailed(OperationFailure(error))
        }
    }
}
