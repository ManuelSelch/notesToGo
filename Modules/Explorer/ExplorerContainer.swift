import SwiftUI
import Router
import Dependencies

enum ExplorerRoute: RouteType {
    case dashboard(path: URL?)
    case createNoteSheet(path: URL?)
    case createFolderSheet(path: URL?)
    
    var id: Self { self }
}

struct ExplorerContainer: View {
    @Dependency(\.router) var router
    @Environment(\.scenePhase) private var scenePhase
    
    @State var docs: [Document] = []
    @State var newItemName = ""
    
    let explorer = Explorer()
    
    let route: ExplorerRoute
    
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
                ExplorerView(
                    docs: $docs,
                    noteTapped: { note in router.stack.push(.editor(.editor(note))) },
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
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            QuickNoteToolbar()
                            CreateNoteToolbar()
                            CreateFolderToolbar()
                        }
                    }
            case .createNoteSheet:
                CreateItemSheet(
                    title: "New Note",
                    placeholder: "Note name",
                    buttonTitle: "Create Note",
                    name: $newItemName,
                    locationName: currentFolder?.lastPathComponent,
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
            router.stack.push(.editor(.editor(note)))
        }
    }
    
    func createFolder() {
        let name = trimmedName
        guard !name.isEmpty else { return }
        guard let folder = try? explorer.addFolder(at: currentFolder, name: name) else { return }
        closeSheet()
        router.stack.push(.explorer(.dashboard(path: folder)))
    }
    
    @ViewBuilder
    func QuickNoteToolbar() -> some View {
        Button(action: {
            Task {
                guard let inbox = try? explorer.inboxFolder() else { return }
                guard let note = try? await explorer.addQuickNote(at: inbox) else { return }
                docs.append(.note(note))
                router.stack.push(.editor(.quickNote(note)))
            }
        }) {
            Image(systemName: "square.and.pencil")
        }
    }
    
    @ViewBuilder
    func CreateNoteToolbar() -> some View {
        Button(action: { router.presentSheet(.explorer(.createNoteSheet(path: currentFolder))) }) {
            Image(systemName: "plus.square")
        }
    }
    
    @ViewBuilder
    func CreateFolderToolbar() -> some View {
        Button(action: { router.presentSheet(.explorer(.createFolderSheet(path: currentFolder))) }) {
            Image(systemName: "folder.badge.plus")
        }
    }

}


private struct CreateItemSheet: View {
    let title: String
    let placeholder: String
    let buttonTitle: String
    @Binding var name: String
    let locationName: String?
    let onCancel: () -> Void
    let onCreate: () -> Void
    
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField(placeholder, text: $name)
                
                if let locationName {
                    LabeledContent("Location", value: locationName)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(buttonTitle, action: onCreate)
                        .disabled(trimmedName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ExplorerContainer(route: .dashboard(path: nil))
}
