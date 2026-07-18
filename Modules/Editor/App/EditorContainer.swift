import SwiftUI
import Flux
import Dependencies
import Router
import PDFKit

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
    @EnvironmentObject var theme: Theme
    @ObservedObject var store: FluxStore<EditorFeature>
    @State var multiPage: MultiPageController
    
    let route: EditorFeature.Route
    
    var note: Note
    var pdf: PDFDocument?
    
    init(route: EditorFeature.Route) {
        self.route = route
        
        let note: Note
        switch route {
        case let .editor(value), let .quickNote(value), let .grid(value):
            note = value
        }
        let pdf = PDFDocument(url: note.pdf)
        
        var app = EditorApp()
        let store = app.store(for: note)
        self.store = store
        self.note = note
        self.pdf = pdf
        
        multiPage = MultiPageController()
        
        multiPage.onPageChanged = { [weak multiPage] page in
            multiPage?.selectTool(store.state.selectedTool)
        }
        multiPage.onPencilDoubleTap = {
            guard store.state.mode.isDrawing else { return }
            store.dispatch(.pencilDoubleTap)
        }
        multiPage.onScreenWidthChanged = { [weak multiPage] in
            guard let document = store.state.document else { return }
            multiPage?.rebuildPages(document, pdf)
        }
    }
    
    var body: some View {
        VStack {
            switch(route) {
            case .editor, .quickNote:
                MultiPageView(controller: multiPage)
                    .onAppear(perform: openIfNeeded)
                    .onAppear(perform: applyInitialMode)
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
                    .navigationBarBackButtonHidden() // hide native backup button to be able to save note when user clicks back
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
                        store.dispatch(.save(multiPage.currentMarkups()))
                        router.stack.dismiss()
                    }
                )
                .onAppear(perform: openIfNeeded)
            }
            
        }
        .onChange(of: store.state.document) {
            guard let document = store.state.document else { return }
            multiPage.rebuildPages(document, pdf)
        }
        .onChange(of: store.state.mode) {
            multiPage.updateMode(store.state.mode)
            theme.statusBarHidden = (store.state.mode == .focus)
        }
        .onChange(of: store.state.selectedTool) {
            multiPage.selectTool(store.state.selectedTool)
        }
    }
    
    func openIfNeeded() {
        if store.state.path != note.markup || store.state.document == nil {
            store.dispatch(.open(note.markup))
        }
    }
    
    func applyInitialMode() {
        switch route {
        case .editor:
            store.dispatch(.enableEditMode)
        case .quickNote:
            store.dispatch(.enableFocusMode)
        case .grid:
            break
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
                        store.dispatch(.save(multiPage.currentMarkups()))
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
            Button(action: {
                store.dispatch(.save(multiPage.currentMarkups()))
                router.stack.dismiss()
            }) {
                Image(systemName: "chevron.left")
            }
        }
    }
}
