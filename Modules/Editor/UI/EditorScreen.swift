import SwiftUI
import PaperKit
import PDFKit

struct EditorScreen: View {
    @State private var multiPage = MultiPageController()
    @EnvironmentObject var theme: Theme
    
    let document: MultiPageDocument?
    let pdf: PDFDocument?
    let mode: EditMode
    let selectedTool: PencilTool
    
    let editModeToggled: () -> Void
    let focusModeToggled: () -> Void
    
    let addPageTapped: () -> Void
    let toolSelected: (PencilTool) -> Void
    let openGridTapped: ([UUID: PaperMarkup]) -> Void
    let saveAndCloseTapped: ([UUID: PaperMarkup]) -> Void
    
    let pencilDoubleTapped: () -> Void
    
    var body: some View {
        MultiPageView(controller: multiPage)
            .toolbar {
                if mode != .focus {
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
            .onAppear {
                multiPage.onPageChanged = { page in
                    multiPage.selectTool(selectedTool)
                }
                multiPage.onPencilDoubleTap = {
                    guard mode.isDrawing else { return }
                    pencilDoubleTapped()
                }
                multiPage.onScreenWidthChanged = {
                    guard let document = document else { return }
                    multiPage.rebuildPages(document, pdf)
                }
            }
            .onChange(of: document) {
                guard let document = document else { return }
                multiPage.rebuildPages(document, pdf)
            }
            .onChange(of: mode) {
                multiPage.updateMode(mode)
                theme.statusBarHidden = (mode == .focus)
            }
            .onChange(of: selectedTool) {
                multiPage.selectTool(selectedTool)
            }
    }
}

// MARK: toolbars
extension EditorScreen {
    @ViewBuilder
    func SaveToolbar() -> some View {
        HStack {
            SimpleButton("chevron.left", action: { saveAndCloseTapped(multiPage.currentMarkups()) })
        }
    }
    
    @ViewBuilder
    func PenToolbar() -> some View {
        HStack(spacing: 20) {
            if mode == .write {
                SimpleButton(
                    "pencil", action: { toolSelected(.pen) },
                    color: selectedTool == .eraser ? .black : .blue
                )
                
                SimpleButton(
                    "eraser", action: { toolSelected(.eraser) },
                    color: selectedTool == .eraser ? .blue : .black
                )
            }
        }
        .padding()
    }
    
    @ViewBuilder
    func EditToolbar() -> some View {
        HStack(spacing: 20) {
            switch mode {
            case .read:
                SimpleButton("square.and.pencil", action: editModeToggled)
            case .write:
                SimpleButton("square.grid.2x2", action: {openGridTapped(multiPage.currentMarkups())})
                SimpleButton("plus.rectangle.portrait", action: addPageTapped)
                SimpleButton("viewfinder", action: focusModeToggled)
                SimpleButton("checkmark", action: editModeToggled)
            case .focus:
                Image(systemName: selectedTool == .eraser ? "eraser" : "pencil")
                SimpleButton("arrow.down.right.and.arrow.up.left", action: focusModeToggled)
            }
        }
        .padding()
    }
}

#Preview {
    EditorScreen(
        document: MultiPageDocument(),
        pdf: PDFDocument(),
        mode: .write,
        selectedTool: .pen,
        
        editModeToggled: {},
        focusModeToggled: {},
        
        addPageTapped: {},
        toolSelected: { _ in },
        openGridTapped: { _ in },
        saveAndCloseTapped: { _ in },
        
        pencilDoubleTapped: {}
    )
}

