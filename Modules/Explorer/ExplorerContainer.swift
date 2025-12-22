import SwiftUI
import Router

struct ExplorerContainer: View {
    @State var docs: [Document] = []
    @State var showCreateNote = false
    @State var selectedFolder: URL? = nil
    
    let explorer = Explorer()
    
    var body: some View {
        NavigationStack {
            ExplorerView(docs: $docs)
                .onAppear {
                    Task {
                        docs = (try? await explorer.loadAllDocs()) ?? []
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing, content: CreateToolbar)
                }
                .sheet(isPresented: $showCreateNote) {
                    VStack {
                        Button(action: {
                            Task {
                                guard let note = try? await explorer.addNote(at: selectedFolder, name: "NewNote") else { return }
                                docs.append(.note(note))
                                
                                MyRouter.shared.push(.editor)
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
        Button(action: { showCreateNote = true }) {
            Image(systemName: "plus")
        }
    }

}


#Preview {
    ExplorerContainer()
}
