import SwiftUI
import Router
import Dependencies

enum ExplorerRoute: RouteType {
    case dashboard(path: URL?)
    case createSheet(path: URL?)
    
    var id: Self { self }
}

struct ExplorerContainer: View {
    @Dependency(\.router) var router
    
    @State var docs: [Document] = []
    @State var newNoteName = ""
    
    let explorer = Explorer()
    
    let route: ExplorerRoute
    
    var currentFolder: URL? {
        switch route {
        case let .dashboard(path), let .createSheet(path):
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
                    .onAppear {
                        Task {
                            docs = (try? await explorer.loadAllDocs(in: currentFolder)) ?? []
                        }
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            QuickNoteToolbar()
                            CreateToolbar()
                        }
                    }
            case .createSheet:
                VStack(alignment: .leading, spacing: 20) {
                    Text("Create")
                        .font(.title2)
                        .bold()
                    
                    TextField("Name", text: $newNoteName)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        Button("Cancel") {
                            newNoteName = ""
                            router.sheet = nil
                        }
                        
                        Spacer()
                        
                        Button("Add Note") {
                            let name = newNoteName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !name.isEmpty else { return }
                            
                            Task {
                                guard let note = try? await explorer.addNote(at: currentFolder, name: name) else { return }
                                newNoteName = ""
                                router.sheet = nil
                                router.stack.push(.editor(.editor(note)))
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newNoteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    Button("Add Folder") {
                        let name = newNoteName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        
                        do {
                            let folder = try explorer.addFolder(at: currentFolder, name: name)
                            newNoteName = ""
                            router.sheet = nil
                            router.stack.push(.explorer(.dashboard(path: folder)))
                        } catch {
                            return
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(newNoteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .presentationDetents([.medium])
            }
            
        }
    }
    
    @ViewBuilder
    func QuickNoteToolbar() -> some View {
        Button(action: {
            Task {
                guard let note = try? await explorer.addQuickNote(at: currentFolder) else { return }
                docs.append(.note(note))
                router.stack.push(.editor(.quickNote(note)))
            }
        }) {
            Image(systemName: "square.and.pencil")
        }
    }
    
    @ViewBuilder
    func CreateToolbar() -> some View {
        Button(action: { router.presentSheet(.explorer(.createSheet(path: currentFolder))) }) {
            Image(systemName: "plus")
        }
    }

}


#Preview {
    ExplorerContainer(route: .dashboard(path: nil))
}
