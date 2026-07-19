import SwiftUI
import Router
import Dependencies
import Flux

struct ExplorerApp {
    func build() -> FluxStore<ExplorerFeature> {
        return .init(
            state: .init(),
            middlewares: [
                ExplorerMiddleware().handle,
                LogMiddleware<ExplorerFeature>().handle
            ]
        )
    }
}

struct ExplorerContainer: View {
    @Dependency(\.router) var router
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var store: FluxStore<ExplorerFeature>
    
    let route: ExplorerRoute
    
    let openNoteTapped: (Note) -> Void
    let openQuickNoteTapped: (Note) -> Void

    var currentFolder: URL? {
        switch route {
        case let .dashboard(path), let .createNoteSheet(path), let .createFolderSheet(path):
            return path
        }
    }

    init(_ store: FluxStore<ExplorerFeature>, route: ExplorerRoute, openNoteTapped: @escaping (Note) -> Void, openQuickNoteTapped: @escaping (Note) -> Void) {
        self.store = store
        self.route = route
        self.openNoteTapped = openNoteTapped
        self.openQuickNoteTapped = openQuickNoteTapped
    }

    var body: some View {
        VStack {
            switch route {
            case .dashboard:
                ExplorerScreen(
                    docs: store.state.docs,
                    noteTapped: openNoteTapped,
                    folderTapped: { folder in router.stack.push(.explorer(.dashboard(path: folder))) }
                )
                .onAppear { store.dispatch(.reloadDocs(currentFolder)) }
                .onChange(of: scenePhase) {
                    if scenePhase == .active {
                        store.dispatch(.reloadDocs(currentFolder))
                    }
                }
                .refreshable {
                    store.dispatch(.reloadDocs(currentFolder))
                }
                .toolbar {
                    ToolbarItemGroup(placement: .topBarLeading) { LeftToolbar() }
                    ToolbarItemGroup(placement: .topBarTrailing) { RightToolbar() }
                }

            case .createNoteSheet:
                CreateItemSheet(
                    title: "New Note",
                    placeholder: "Note name",
                    buttonTitle: "Create Note",
                    name: store.state.newItemName,
                    locationName: currentFolder?.lastPathComponent,
                    textFieldAccessibilityIdentifier: "explorer.createNote.nameField",
                    confirmButtonAccessibilityIdentifier: "explorer.createNote.confirmButton",
                    nameChanged: { store.dispatch(.newItemNameChanged($0)) },
                    onCancel: closeSheet,
                    onCreate: { store.dispatch(.createNoteTapped(currentFolder)) }
                )

            case .createFolderSheet:
                CreateItemSheet(
                    title: "New Folder",
                    placeholder: "Folder name",
                    buttonTitle: "Create Folder",
                    name: store.state.newItemName,
                    locationName: currentFolder?.lastPathComponent,
                    textFieldAccessibilityIdentifier: "explorer.createFolder.nameField",
                    confirmButtonAccessibilityIdentifier: "explorer.createFolder.confirmButton",
                    nameChanged: { store.dispatch(.newItemNameChanged($0)) },
                    onCancel: closeSheet,
                    onCreate: { store.dispatch(.createFolderTapped(currentFolder)) }
                )
            }
        }
        .onChange(of: store.state.pendingDestination) {
            guard let pending = store.state.pendingDestination else { return }

            switch pending {
            case let .note(note):
                router.sheet = nil
                openNoteTapped(note)
            case let .quickNote(note):
                openQuickNoteTapped(note)
            case let .folder(folder):
                router.sheet = nil
                router.stack.push(.explorer(.dashboard(path: folder)))
            }

            store.dispatch(.pendingDestinationHandled)
        }
    }

    func closeSheet() {
        store.dispatch(.clearNewItemName)
        router.sheet = nil
    }
}

extension ExplorerContainer {
    @ViewBuilder
    func LeftToolbar() -> some View {
        HStack {
            if currentFolder == nil {
                SimpleButton("gear", action: { router.presentSheet(.settings(.settings)) })
            }
            
        }
    }

    @ViewBuilder
    func RightToolbar() -> some View {
        HStack {
            SimpleButton("square.and.pencil", action: {
                store.dispatch(.createQuickNoteTapped)
            })
            SimpleButton("plus.square", action: { router.presentSheet(.explorer(.createNoteSheet(path: currentFolder))) })
                .accessibilityIdentifier("explorer.createNoteButton")
            SimpleButton("folder.badge.plus", action: { router.presentSheet(.explorer(.createFolderSheet(path: currentFolder))) })
                .accessibilityIdentifier("explorer.createFolderButton")
        }
    }
}
