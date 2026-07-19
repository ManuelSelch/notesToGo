import SwiftUI
import Router
import Dependencies

struct ExplorerContainer: View {
    @Dependency(\.router) var router
    @Environment(\.scenePhase) private var scenePhase
    
    @State var docs: [Document] = []
    @State var newItemName = ""
    
    let explorer = Explorer()
    let route: ExplorerRoute
    
    let openNoteTapped: (Note) -> Void
    let openQuickNoteTapped: (Note) -> Void
    
    var currentFolder: URL? {
        switch route {
        case let .dashboard(path), let .createNoteSheet(path), let .createFolderSheet(path):
            return path
        }
    }
    
    var body: some View {
        VStack {
            switch(route) {
            case .dashboard:
                ExplorerScreen(
                    docs: $docs,
                    noteTapped: openNoteTapped,
                    folderTapped: { folder in router.stack.push(.explorer(.dashboard(path: folder)))}
                )
                    .onAppear(perform: reloadDocs)
                    .onChange(of: scenePhase) {
                        if scenePhase == .active {
                            reloadDocs()
                        }
                    }
                    .refreshable {
                        reloadDocs()
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
                    name: $newItemName,
                    locationName: currentFolder?.lastPathComponent,
                    textFieldAccessibilityIdentifier: "explorer.createNote.nameField",
                    confirmButtonAccessibilityIdentifier: "explorer.createNote.confirmButton",
                    onCancel: closeSheet,
                    onCreate: createNote
                )
            case .createFolderSheet:
                CreateItemSheet(
                    title: "New Folder",
                    placeholder: "Folder name",
                    buttonTitle: "Create Folder",
                    name: $newItemName,
                    locationName: currentFolder?.lastPathComponent,
                    textFieldAccessibilityIdentifier: "explorer.createFolder.nameField",
                    confirmButtonAccessibilityIdentifier: "explorer.createFolder.confirmButton",
                    onCancel: closeSheet,
                    onCreate: createFolder
                )
            }
            
        }
    }
    
    var trimmedName: String {
        newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func reloadDocs() {
        Task {
            docs = (try? await explorer.loadAllDocs(in: currentFolder)) ?? []
        }
    }
    
    func closeSheet() {
        newItemName = ""
        router.sheet = nil
    }
    
    func createNote() {
        let name = trimmedName
        guard !name.isEmpty else { return }
        
        Task {
            guard let note = try? await explorer.addNote(at: currentFolder, name: name) else { return }
            closeSheet()
            openNoteTapped(note)
        }
    }
    
    func createFolder() {
        let name = trimmedName
        guard !name.isEmpty else { return }
        guard let folder = try? explorer.addFolder(at: currentFolder, name: name) else { return }
        closeSheet()
        router.stack.push(.explorer(.dashboard(path: folder)))
    }
}

extension ExplorerContainer {
    @ViewBuilder
    func LeftToolbar() -> some View {
        HStack {
            if currentFolder != nil {
                SimpleButton("chevron.left", action: { router.stack.dismiss() })
                    .accessibilityIdentifier("explorer.backButton")
            }
            SimpleButton("gear", action: {router.presentSheet(.settings(.settings))})
        }
    }
    
    @ViewBuilder
    func RightToolbar() -> some View {
        HStack {
            SimpleButton("square.and.pencil", action: {
                Task {
                    guard let inbox = try? explorer.inboxFolder() else { return }
                    guard let note = try? await explorer.addQuickNote(at: inbox) else { return }
                    docs.append(.note(note))
                    openQuickNoteTapped(note)
                }
            })
            SimpleButton("plus.square", action: { router.presentSheet(.explorer(.createNoteSheet(path: currentFolder))) })
                .accessibilityIdentifier("explorer.createNoteButton")
            SimpleButton("folder.badge.plus", action: { router.presentSheet(.explorer(.createFolderSheet(path: currentFolder))) })
                .accessibilityIdentifier("explorer.createFolderButton")
        }
    }
}
