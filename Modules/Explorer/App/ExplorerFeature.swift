import Foundation
import Flux

nonisolated struct ExplorerFeature: Feature {
    struct State: Equatable, Sendable {
        enum PendingDestination: Equatable, Sendable {
            case note(Note)
            case quickNote(Note)
            case folder(URL)
        }

        var docs: [Document] = []
        var newItemName = ""
        var pendingDestination: PendingDestination?

        var trimmedNewItemName: String {
            newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    enum Action: Equatable, Sendable {
        case reloadDocs(URL?)
        case docsLoaded([Document])

        case newItemNameChanged(String)
        case clearNewItemName

        case createNoteTapped(URL?)
        case noteCreated(Note)

        case createFolderTapped(URL?)
        case folderCreated(URL)

        case createQuickNoteTapped
        case quickNoteCreated(Note)

        case pendingDestinationHandled
    }
    
    func reduce(_ state: inout State, _ action: Action) {
        switch action {
        case let .docsLoaded(docs):
            state.docs = docs

        case let .newItemNameChanged(name):
            state.newItemName = name

        case .clearNewItemName:
            state.newItemName = ""

        case let .noteCreated(note):
            state.newItemName = ""
            state.pendingDestination = .note(note)

        case let .folderCreated(folder):
            state.newItemName = ""
            state.pendingDestination = .folder(folder)

        case let .quickNoteCreated(note):
            state.pendingDestination = .quickNote(note)

        case .pendingDestinationHandled:
            state.pendingDestination = nil

        default:
            break
        }
    }
}
