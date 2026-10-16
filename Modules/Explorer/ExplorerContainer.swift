import SwiftUI
import Router
import Dependencies
import Flux

struct ExplorerContainer: View {
    @Dependency(\.router) var router
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var store: FluxStore<ExplorerFeature>
    
    let route: ExplorerRoute
    
    let openNoteTapped: (Note) -> Void
    let openQuickNoteTapped: (Note) -> Void

    var currentFolder: URL? {
        switch route {
        case let .dashboard(path), let .createNoteSheet(path), let .createFolderSheet(path):
            return path
        }
    }

    init(
        route: ExplorerRoute,
        openNoteTapped: @escaping (Note) -> Void, openQuickNoteTapped: @escaping (Note) -> Void
    ) {
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
                .disabled(store.state.isLoading)
                .overlay {
                    if store.state.isLoading { ProgressView("Loading…") }
                }
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
                    if(currentFolder == nil) {
                        ToolbarItemGroup(placement: .topBarLeading) { LeftToolbar() }
                    }
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
                .disabled(store.state.isLoading)
                .interactiveDismissDisabled(store.state.isLoading)

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
                .disabled(store.state.isLoading)
                .interactiveDismissDisabled(store.state.isLoading)
            }
        }
        .alert(store.state.lastOperation?.title ?? "Operation failed", isPresented: Binding(
            get: { shouldPresentFailure },
            set: { if !$0 { store.dispatch(.dismissFailure) } }
        )) {
            Button("Retry") { store.dispatch(.retryOperation) }
                .accessibilityIdentifier("explorer.retryOperationButton")
            Button(isCreationSheet ? "Edit name" : "Cancel", role: .cancel) {
                store.dispatch(.dismissFailure)
            }
        } message: {
            Text(store.state.failure?.message ?? "")
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

    private var isCreationSheet: Bool {
        switch route {
        case .createNoteSheet, .createFolderSheet: return true
        case .dashboard: return false
        }
    }

    private var shouldPresentFailure: Bool {
        guard store.state.failure != nil, let operation = store.state.lastOperation else { return false }
        switch (route, operation) {
        case (.createNoteSheet, .createNote), (.createFolderSheet, .createFolder),
             (.dashboard, .reload), (.dashboard, .createQuickNote): return true
        default: return false
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
            SimpleButton("gear", action: { router.presentSheet(.settings(.settings)) })
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
        .disabled(store.state.isLoading)
    }
}
