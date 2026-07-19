import Foundation
import Flux

final class ExplorerMiddleware {
    private let explorer = Explorer()

    func handle(state: ExplorerFeature.State, action: ExplorerFeature.Action) async -> ExplorerFeature.Action? {
        switch action {
        case let .reloadDocs(folder):
            let docs = (try? await explorer.loadAllDocs(in: folder)) ?? []
            return .docsLoaded(docs)

        case let .createNoteTapped(folder):
            let name = state.trimmedNewItemName
            guard !name.isEmpty else { return .none }
            guard let note = try? await explorer.addNote(at: folder, name: name) else { return .none }
            return .noteCreated(note)

        case let .createFolderTapped(folder):
            let name = state.trimmedNewItemName
            guard !name.isEmpty else { return .none }
            guard let folder = try? explorer.addFolder(at: folder, name: name) else { return .none }
            return .folderCreated(folder)

        case .createQuickNoteTapped:
            guard let inbox = try? explorer.inboxFolder() else { return .none }
            guard let note = try? await explorer.addQuickNote(at: inbox) else { return .none }
            return .quickNoteCreated(note)

        default:
            return .none
        }
    }
}
