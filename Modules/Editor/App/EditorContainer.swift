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
    @ObservedObject var store: FluxStore<EditorFeature>
    
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
    }
    
    var body: some View {
        VStack {
            switch(route) {
            case .editor, .quickNote:
                EditorScreen(
                    document: store.state.document,
                    pdf: pdf,
                    mode: store.state.mode,
                    selectedTool: store.state.selectedTool,
                    
                    editModeToggled: {store.dispatch(.toggleEditMode)},
                    focusModeToggled: {store.dispatch(.toggleFocusMode)},
                    
                    addPageTapped: {store.dispatch(.addPageTapped)},
                    toolSelected: {store.dispatch(.toolSelected($0))},
                    openGridTapped: {
                        store.dispatch(.save($0))
                        router.stack.push(.editor(.grid(note)))
                    },
                    saveAndCloseTapped: {
                        store.dispatch(.save($0))
                        router.stack.dismiss()
                    },
                    
                    pencilDoubleTapped: { store.dispatch(.pencilDoubleTap) }
                )
                .onAppear(perform: openIfNeeded)
                .onAppear(perform: applyInitialMode)
                .navigationBarBackButtonHidden() // hide native backup button to be able to save note when user clicks back
                .ignoresSafeArea(.all)
            
            case .grid:
                GridScreen(
                    pages: store.state.document?.pages ?? [],
                    hasCopiedPage: store.state.copiedPage != nil,
                    onAddPage: { store.dispatch(.insertPage(after: $0)) },
                    onCopyPage: { store.dispatch(.copyPage($0)) },
                    onPastePage: { store.dispatch(.pastePage(after: $0)) },
                    onMovePage: { store.dispatch(.movePage(source: $0, destination: $1)) },
                    onDone: { router.stack.dismiss() }
                )
                .onAppear(perform: openIfNeeded)
            }
            
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
}
