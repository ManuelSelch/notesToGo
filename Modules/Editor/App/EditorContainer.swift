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
        controller.onPencilDoubleTap = {
            guard store.state.mode.isDrawing else { return }
            store.dispatch(.pencilDoubleTap)
        }
        controller.document = store.state.document
    }
    
    var body: some View {
        VStack {
            switch(route) {
            case let .editor(note):
                MultiPageView(controller: controller)
                    .onAppear { store.dispatch(.open(note.markup)) }
                    .toolbar {
                        if store.state.mode != .focus {
                            ToolbarItem(placement: .topBarLeading) {
                                SaveToolbar()
                            }
                        }
                                                                                                                                                                                 
                        ToolbarItem(placement: .principal) {
                            PenToolbar()
                        }
                                                                                                                                                                                 
                        ToolbarItem(placement: .topBarTrailing) {
                            EditToolbar()
                        }
                    }
                    .navigationBarBackButtonHidden(store.state.mode == .focus)
            
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
        .onChange(of: store.state.selectedTool) {
            controller.selectTool(store.state.selectedTool)
        }
        .ignoresSafeArea(.all)
    }
    
    @ViewBuilder
    func EditToolbar() -> some View {
        HStack(spacing: 20) {
            switch store.state.mode {
               case .read:
                   Button(action: { store.dispatch(.toggleEditMode) }) {
                       Image(systemName: "square.and.pencil")
                   }
                                                                                                                                                                         
               case .write:
                    Button(action: { router.stack.push(.editor(.grid)) }) {
                        Image(systemName: "square.grid.2x2")
                    }
                                                                                                                                                                         
                    Button(action: { store.dispatch(.addPageTapped) }) {
                        Image(systemName: "plus.rectangle.portrait")
                    }
                
                                                                                                                                                                         
                    Button(action: { store.dispatch(.toggleFocusMode) }) {
                        Image(systemName: "viewfinder")
                    }
                                                                                                                                                                         
                    Button(action: { store.dispatch(.toggleEditMode) }) {
                        Image(systemName: "checkmark")
                    }
                                                                                                                                                                         
               case .focus:
                    Image(systemName:
                        store.state.selectedTool == .eraser ? "eraser" : "pencil"
                    )
                                                                                                                                                                         
                    Button(action: { store.dispatch(.toggleFocusMode) }) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                    }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    func PenToolbar() -> some View {
        HStack(spacing: 20) {
            if store.state.mode == .write {
                Button(action: { store.dispatch(.toolSelected(.pen)) }) {
                    Image(systemName: "pencil")
                        .foregroundStyle(store.state.selectedTool == .eraser ? .black : .blue)
                }
                
                Button(action: { store.dispatch(.toolSelected(.eraser)) }) {
                    Image(systemName: "eraser")
                        .foregroundStyle(store.state.selectedTool == .eraser ? .blue : .black)
                }
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
