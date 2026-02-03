import SwiftUI
import Router
import Dependencies

enum ExplorerRoute: RouteType {
    case dashboard(path: URL?)
    case createSheet
    
    var id: Self { self }
}

struct ExplorerContainer: View {
    @Dependency(\.router) var router
    
    @State var docs: [Document] = []
    @State var selectedFolder: URL? = nil
    
    let explorer = Explorer()
    
    let route: ExplorerRoute
    
    var body: some View {
        VStack {
            switch(route) {
            case .dashboard:
                ExplorerView(
                    docs: $docs,
                    noteTapped: { note in router.stack.push(.editor(note)) },
                    folderTapped: { folder in router.stack.push(.explorer(.dashboard(path: folder)))}
                )
                    .onAppear {
                        Task {
                            docs = (try? await explorer.loadAllDocs()) ?? []
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing, content: CreateToolbar)
                    }
            case .createSheet:
                VStack {
                    Button(action: {
                        Task {
                            guard let note = try? await explorer.addNote(at: selectedFolder, name: "NewNote") else { return }
                            docs.append(.note(note))
                            
                            router.sheet = nil
                            router.stack.push(.editor(note))
                        }
                    }) {
                        Text("Add Note")
                    }
                    
                    Button(action: {
                        
                    }) {
                        Text("Add Folder")
                    }
                }
                .presentationDetents([.medium])
            }
            
        }
    }
    
    @ViewBuilder
    func CreateToolbar() -> some View {
        Button(action: { router.presentSheet(.explorer(.createSheet)) }) {
            Image(systemName: "plus")
        }
    }

}


#Preview {
    ExplorerContainer(route: .dashboard(path: nil))
}
