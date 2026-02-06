import SwiftUI
import Flux
import Dependencies
import Router

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
    @Dependency(\.router) var router
    @ObservedObject var store: FluxStore<EditorFeature>
    @State var controller: MultiPageController
    
    let route: EditorFeature.Route
    
    init(route: EditorFeature.Route) {
        self.route = route
        
        let store = EditorApp().build()
        self.store = store
        
        controller = MultiPageController(
            onPageChanged: { _ in }
        )
        controller.document = store.state.document
    }
    
    var body: some View {
        VStack {
            switch(route) {
            case let .editor(note):
                MultiPageView(controller: controller)
                    .onAppear { store.dispatch(.open(note.markup)) }
                    .toolbar {
                        if(store.state.mode != .focus) {
                            ToolbarItem(placement: .topBarLeading, content: SaveToolbar)
                        }
                        
                        ToolbarItem(placement: .topBarTrailing, content: EditToolbar)
                    }
            
            case .grid:
                GridView(pages: store.state.document?.pages ?? [])
            }
            
        }
        .onChange(of: store.state.document) {
            controller.document = store.state.document
        }
        .onChange(of: store.state.mode) {
            controller.updateMode(store.state.mode)
        }
        .ignoresSafeArea(.all)
    }
    
    @ViewBuilder
    func EditToolbar() -> some View {
        HStack(spacing: 20) {
            if(store.state.mode != .focus) {
                Button(action: { router.stack.push(.editor(.grid)) }) {
                    Image(systemName: "square.grid.2x2")
                }
                
                
                Button(action: { store.dispatch(.addPageTapped) }) {
                    Image(systemName: "plus.rectangle.portrait")
                }
                
                Button(action: { store.dispatch(.toggleEditMode) }) {
                    Image(systemName: store.state.mode.isDrawing ? "pencil.slash": "square.and.pencil")
                }
            }
            
            Button(action: { store.dispatch(.toggleFocusMode) }) {
                Image(systemName: "circle")
            }
        }
        .padding()
    }
    
    @ViewBuilder
    func SaveToolbar() -> some View {
        HStack {
            Button(action: { store.dispatch(.save(controller.currentMarkups())) }) {
                Image(systemName: "square.and.arrow.down")
            }
        }
    }
}
