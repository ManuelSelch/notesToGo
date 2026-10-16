import SwiftUI
import Flux
import Dependencies
import Router
import PDFKit
import Pulse

class LogMiddleware<F> where F:Feature {
    func handle(state: F.State, action: F.Action) async -> F.Action? {
        LoggerStore.shared.storeMessage(label: "Redux", level: .debug, message: "\(action)")
        return .none
    }
}

struct EditorApp {
    func build(repository: DocumentRepositoryProtocol? = nil) -> FluxStore<EditorFeature> {
        return .init(
            state: .init(),
            middlewares: [
                DocumentMiddleware(repository: repository).handle,
                PageMiddleware().handle,
                LogMiddleware<EditorFeature>().handle
            ]
        )
    }
}

struct EditorContainer: View {
    @Dependency(\.router) var router
    @EnvironmentObject var store: FluxStore<EditorFeature>
    
    let route: EditorFeature.Route
    var pdf: PDFDocument?
    
    init(_ route: EditorFeature.Route) {
        self.route = route
    }
    
    var body: some View {
        VStack {
            switch(route) {
            case .editor:
                if let failure = store.state.loadFailure {
                    EditorLoadErrorView(
                        message: failure.message,
                        retryTapped: { store.dispatch(.retryLoad) },
                        backTapped: {
                            store.dispatch(.dismissLoadFailure)
                            router.stack.dismiss()
                        }
                    )
                    .navigationBarBackButtonHidden()
                } else if store.state.document == nil {
                    EditorLoadingView(backTapped: { router.stack.dismiss() })
                        .navigationBarBackButtonHidden()
                } else {
                    EditorScreen(
                        document: store.state.document,
                        pdf: pdf,
                        mode: store.state.mode,
                        tools: store.state.tools,
                        selectedTool: store.state.selectedTool,
                        canSave: store.state.canSave,
                        isSaving: store.state.isSaving,

                        editModeToggled: {store.dispatch(.toggleEditMode)},
                        focusModeToggled: {store.dispatch(.toggleFocusMode)},

                        addPageTapped: {store.dispatch(.addPageTapped)},
                        toolSelected: {store.dispatch(.toolSelected($0))},
                        contentChanged: { store.dispatch(.canvasChanged($0)) },
                        saveTapped: { store.dispatch(.save($0)) },
                        openGridTapped: {
                            store.dispatch(.captureMarkups($0))
                            router.stack.push(.editor(.grid))
                        },
                        saveAndCloseTapped: {
                            store.dispatch(.save($0))
                            router.stack.dismiss()
                        },

                        pencilDoubleTapped: { store.dispatch(.pencilDoubleTap) },
                        bottomOverscrolled: { store.dispatch(.addPageTapped) },
                    )
                    .disabled(store.state.isLoading)
                    .onChange(of: store.state.note) {
                        // guard let note = store.state.note else { return }
                        // pdf = PDFDocument(url: note.pdf)
                    }
                }
            
            case .grid:
                GridScreen(
                    pages: store.state.document?.pages ?? [],
                    hasCopiedPage: store.state.copiedPage != nil,
                    onAddPage: { store.dispatch(.insertPageTapped(after: $0)) },
                    onCopyPage: { store.dispatch(.copyPage($0)) },
                    onPastePage: { store.dispatch(.pastePageTapped(after: $0)) },
                    onMovePage: { store.dispatch(.movePage(source: $0, destination: $1)) },
                    onDone: { router.stack.dismiss() }
                )
                .disabled(store.state.isLoading || store.state.isSaving)
            }
            
        }
    }
}
