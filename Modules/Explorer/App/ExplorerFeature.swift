import Foundation
import Flux

nonisolated struct ExplorerFeature: Feature {
    struct State: Equatable, Sendable {
        enum PendingDestination: Equatable, Sendable {
            case note(Note)
            case quickNote(Note)
            case folder(URL)
        }

        enum Operation: Equatable, Sendable {
            case reload(URL?)
            case createNote(URL?)
            case createFolder(URL?)
            case createQuickNote

            var title: String {
                switch self {
                case .reload: return "Couldn’t load files"
                case .createNote, .createQuickNote: return "Couldn’t create note"
                case .createFolder: return "Couldn’t create folder"
                }
            }
        }

        var docs: [Document] = []
        var isLoading = false
        var failure: OperationFailure?
        var lastOperation: Operation?
        var newItemName = ""
        var pendingDestination: PendingDestination?

        var trimmedNewItemName: String {
            newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    enum Action: Equatable, Sendable {
        case reloadDocs(URL?)
        case docsLoaded([Document])
        case operationFailed(OperationFailure)
        case retryOperation
        case dismissFailure

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
        case let .reloadDocs(folder):
            state.lastOperation = .reload(folder)
            state.isLoading = true
            state.failure = nil
        case let .createNoteTapped(folder):
            state.lastOperation = .createNote(folder)
            state.isLoading = true
            state.failure = nil
        case let .createFolderTapped(folder):
            state.lastOperation = .createFolder(folder)
            state.isLoading = true
            state.failure = nil
        case .createQuickNoteTapped:
            state.lastOperation = .createQuickNote
            state.isLoading = true
            state.failure = nil
        case .retryOperation:
            guard state.lastOperation != nil else { break }
            state.isLoading = true
            state.failure = nil
        case let .operationFailed(failure):
            state.isLoading = false
            state.failure = failure
            state.pendingDestination = nil
        case .dismissFailure:
            state.failure = nil
        case let .docsLoaded(docs):
            state.docs = docs
            state.isLoading = false
            state.failure = nil

        case let .newItemNameChanged(name):
            state.newItemName = name

        case .clearNewItemName:
            state.newItemName = ""
            state.failure = nil

        case let .noteCreated(note):
            state.isLoading = false
            state.failure = nil
            state.newItemName = ""
            state.pendingDestination = .note(note)

        case let .folderCreated(folder):
            state.isLoading = false
            state.failure = nil
            state.newItemName = ""
            state.pendingDestination = .folder(folder)

        case let .quickNoteCreated(note):
            state.isLoading = false
            state.failure = nil
            state.pendingDestination = .quickNote(note)

        case .pendingDestinationHandled:
            state.pendingDestination = nil

        }
    }
}
