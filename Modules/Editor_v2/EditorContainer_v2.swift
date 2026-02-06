import SwiftUI
import Flux
import Dependencies

struct EditorContainer_v2: View {
    @ObservedObject var store: FluxStore<EditorFeature>
    @State var controller: MultiPageController
    
    let note: Note
    
    init(note: Note) {
        self.note = note
        

        
        var store: FluxStore<EditorFeature> = .init(
            state: .init(),
            middlewares: [
                DocumentMiddleware(repo: InMemoryDocumentRepository()).handle
            ]
        )
        self.store = store
        
        controller = MultiPageController(
            onPageChanged: { store.dispatch(.pageChanged($0)) }
        )
        
        controller.document = store.state.document
    }
    
    var body: some View {
        VStack {
            Text("pages: \(store.state.document?.pages.count ?? -1)")
            Text("current: \(store.state.currentPage)")
            
            MultiPageView(controller: controller)
        }
        .onChange(of: store.state.document) {
            controller.document = store.state.document
        }
        .onAppear { store.dispatch(.open(note.markup)) }
        .toolbar {
            ToolbarItem(placement: .topBarLeading, content: SaveToolbar)
            ToolbarItem(placement: .topBarTrailing, content: EditToolbar)
        }
        .ignoresSafeArea(.all)
    }
    
    @ViewBuilder
    func EditToolbar() -> some View {
        HStack {
            Button("Add Page") {
                store.dispatch(.addPageTapped)
            }
            
            Button(store.state.mode.isEditing ? "Done": "Draw") {
                store.dispatch(.toggleEditMode)
            }
        }
    }
    
    @ViewBuilder
    func SaveToolbar() -> some View {
        HStack {
            Button("Save") {
                
            }
        }
    }
}

#Preview {
    EditorContainer_v2(note: .init(pdf: .applicationDirectory, markup: .applicationDirectory))
}
