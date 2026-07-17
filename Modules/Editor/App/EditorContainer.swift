import SwiftUI
import Flux
import Dependencies
import Router

struct EditorApp {
    @Dependency(\.documentRepository) var repo
    private static var storesByPath: [URL: FluxStore<EditorFeature>] = [:]
    
    func build() -> FluxStore<EditorFeature> {
         return .init(
            state: .init(),
            middlewares: [
                DocumentMiddleware(repo: repo).handle
            ]
        )
    }
    
    mutating func store(for note: Note) -> FluxStore<EditorFeature> {
        if let existing = Self.storesByPath[note.markup] {
            return existing
        }
        let store = build()
        Self.storesByPath[note.markup] = store
        return store
    }
}

struct EditorContainer: View {
    @Dependency(\.router) var router
    @ObservedObject var store: FluxStore<EditorFeature>
    @State var controller: MultiPageController
    
    let route: EditorFeature.Route
    
    var note: Note {
        switch route {
        case let .editor(note), let .grid(note):
            return note
        }
    }
    
    init(route: EditorFeature.Route) {
        self.route = route
        
        let note: Note
        switch route {
        case let .editor(value), let .grid(value):
            note = value
        }
        
        var app = EditorApp()
        let store = app.store(for: note)
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
            case .editor:
                MultiPageView(controller: controller)
                    .onAppear(perform: openIfNeeded)
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
                    .ignoresSafeArea(.all)
            
            case .grid:
                GridView(
                    pages: store.state.document?.pages ?? [],
                    hasCopiedPage: store.state.copiedPage != nil,
                    onAddPage: { store.dispatch(.insertPage(after: $0)) },
                    onCopyPage: { store.dispatch(.copyPage($0)) },
                    onPastePage: { store.dispatch(.pastePage(after: $0)) },
                    onMovePage: { store.dispatch(.movePage(source: $0, destination: $1)) },
                    onDone: {
                        store.dispatch(.save(controller.currentMarkups()))
                        router.stack.dismiss()
                    }
                )
                .onAppear(perform: openIfNeeded)
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
        
    }
    
    func openIfNeeded() {
        if store.state.path != note.markup || store.state.document == nil {
            store.dispatch(.open(note.markup))
        }
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
                    Button(action: {
                        store.dispatch(.save(controller.currentMarkups()))
                        router.stack.push(.editor(.grid(note)))
                    }) {
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
