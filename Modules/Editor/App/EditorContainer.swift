import SwiftUI
import Flux
import Dependencies

struct EditorApp {
    @Dependency(\.documentRepository) var repo
    
    func build() -> FluxStore<EditorFeature> {
         return .init(
            state: .init(),
            middlewares: [
                DocumentMiddleware(repo: repo).handle
            ]
        )
    }
}

struct EditorContainer: View {
    @ObservedObject var store: FluxStore<EditorFeature>
    @State var controller: MultiPageController
    
    let note: Note
    
    init(note: Note) {
        self.note = note
        
        let store = EditorApp().build()
        self.store = store
        
        controller = MultiPageController(
            onPageChanged: { _ in }
        )
        controller.document = store.state.document
    }
    
    var body: some View {
        VStack {
            Text("pages: \(store.state.document?.pages.count ?? -1)")
            
            MultiPageView(controller: controller)
        }
        .onAppear { store.dispatch(.open(note.markup)) }
        .onChange(of: store.state.document) {
            controller.document = store.state.document
        }
        .onChange(of: store.state.mode) {
            controller.updateMode(store.state.mode)
        }
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
            
            Button(store.state.mode.isDrawing ? "Done": "Draw") {
                store.dispatch(.toggleEditMode)
            }
        }
    }
    
    @ViewBuilder
    func SaveToolbar() -> some View {
        HStack {
            Button("Save") {
                store.dispatch(.save(controller.currentMarkups()))
            }
        }
    }
}

#Preview {
    EditorContainer(note: .init(pdf: .applicationDirectory, markup: .applicationDirectory))
}
