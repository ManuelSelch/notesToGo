import SwiftUI
import Flux
import Dependencies
import Router
import PDFKit

struct EditorApp {
    func build() -> FluxStore<EditorFeature> {
         return .init(
            state: .init(),
            middlewares: [
                DocumentMiddleware().handle
            ]
        )
    }
}

struct EditorContainer: View {
    @Dependency(\.router) var router
    @ObservedObject var store: FluxStore<EditorFeature>
    
    let route: EditorFeature.Route
    var pdf: PDFDocument?
    
    init(_ store: FluxStore<EditorFeature>, route: EditorFeature.Route) {
        self.route = route
        self.store = store
    }
    
    var body: some View {
        VStack {
            switch(route) {
            case .editor:
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
                        router.stack.push(.editor(.grid))
                    },
                    saveAndCloseTapped: {
                        store.dispatch(.save($0))
                        router.stack.dismiss()
                    },
                    
                    pencilDoubleTapped: { store.dispatch(.pencilDoubleTap) }
                )
                .onChange(of: store.state.note) {
                    // guard let note = store.state.note else { return }
                    // pdf = PDFDocument(url: note.pdf)
                }
            
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
            }
            
        }
    }
}
