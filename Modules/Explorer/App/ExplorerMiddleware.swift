import Foundation
import Flux

final class ExplorerMiddleware {
    private let explorer: ExplorerService

    init(explorer: ExplorerService) {
        self.explorer = explorer
    }

    func handle(state: ExplorerFeature.State, action: ExplorerFeature.Action) async -> ExplorerFeature.Action? {
        let operation: ExplorerFeature.State.Operation
        switch action {
        case let .reloadDocs(folder): operation = .reload(folder)
        case let .createNoteTapped(folder): operation = .createNote(folder)
        case let .createFolderTapped(folder): operation = .createFolder(folder)
        case .createQuickNoteTapped: operation = .createQuickNote
        case .retryOperation:
            guard let previous = state.lastOperation else { return .none }
            operation = previous
        default: return .none
        }

        do {
            switch operation {
            case let .reload(folder):
                return .docsLoaded(try await explorer.loadAllDocs(in: folder))
            case let .createNote(folder):
                return .noteCreated(try await explorer.addNote(at: folder, name: state.trimmedNewItemName))
            case let .createFolder(folder):
                return .folderCreated(try explorer.addFolder(at: folder, name: state.trimmedNewItemName))
            case .createQuickNote:
                let inbox = try explorer.inboxFolder()
                return .quickNoteCreated(try await explorer.addQuickNote(at: inbox))
            }
        } catch {
            return .operationFailed(OperationFailure(error))
        }
    }
}
