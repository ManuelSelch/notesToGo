import Foundation
import FactoryKit
import Flux
import Router

class DocumentMiddleware {
    @Injected(\.documentRepository) var repo
    @Injected(\.router) var router
    
    func handle(state: EditorFeature.State, action: EditorFeature.Action) async -> EditorFeature.Action? {
        switch(action) {
        case let .openNote(note), let .openQuickNote(note):
            guard !state.isSaving else { return .none }
            router.stack.push(.editor(.editor))
            return await load(note, using: repo)
        case .retryLoad:
            guard let note = state.note else { return .none }
            return await load(note, using: repo)
            
        case let .save(_, requestID):
            // Flux middleware receives post-reducer state. Only the accepted request
            // may write; a rapid second tap must not replay the active snapshot.
            guard let request = state.saveRequest, request.id == requestID else { break }
            do {
                try await repo.save(request.document, at: request.note.markup)
                return .saved(request.id)
            } catch { return .savedFailed(request.id, OperationFailure(error)) }
        
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
