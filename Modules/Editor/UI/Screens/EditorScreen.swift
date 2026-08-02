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
    let bottomOverscrolled: () -> Void
    
    let colorChanged: (UIColor) -> Void
    
    var body: some View {
        MultiPageView(controller: multiPage)
            .navigationBarBackButtonHidden() // hide native backup button to be able to save note when user clicks back
            .ignoresSafeArea(.all)
            .onAppear {
                theme.statusBarHidden = (mode == .focus)
            }
            .toolbar {
                if mode != .focus {
                    ToolbarItem(placement: .topBarLeading) { SaveToolbar() }
                }                                                                                                                                                   
                ToolbarItem(placement: .principal) { PenToolbar() }
                ToolbarItem(placement: .topBarTrailing) { EditToolbar() }
            }
            .onAppear(perform: bindControllerCallbacks)
            .onChange(of: document) {
                bindControllerCallbacks()
                guard let document = document else { return }
                multiPage.rebuildPages(document, pdf)
            }
            .onChange(of: mode) {
                bindControllerCallbacks()
                multiPage.updateMode(mode)
                theme.statusBarHidden = (mode == .focus)
            }
            .onChange(of: selectedTool) {
                bindControllerCallbacks()
                multiPage.selectTool(selectedTool)
            }
    }
}

// MARK: controller binding
extension EditorScreen {
    func bindControllerCallbacks() {
        multiPage.onPageChanged = { _ in
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
        multiPage.onBottomOverscrolled = {
            guard mode.isDrawing else { return }
            bottomOverscrolled()
        }
    }
}

// MARK: toolbars
extension EditorScreen {
    @ViewBuilder
    func SaveToolbar() -> some View {
        HStack {
            SimpleButton("chevron.left", action: { saveAndCloseTapped(multiPage.currentMarkups()) })
                .accessibilityIdentifier("editor.closeButton")
        }
    }
    
    @ViewBuilder
    func PenToolbar() -> some View {
        HStack(spacing: 20) {
            if mode == .write {
                SimpleButton(
                    "pencil", action: { toolSelected(.pen(1, .black)) },
                    color: selectedTool == .eraser || selectedTool == .lasso ? .black : .blue
                )
                
                
                SimpleButton(
                    "eraser", action: { toolSelected(.eraser) },
                    color: selectedTool == .eraser ? .blue : .black
                )
                
                SimpleButton(
                    "lasso", action: { toolSelected(.lasso) },
                    color: selectedTool == .lasso ? .blue : .black
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
                switch selectedTool {
                case let .pen(_, color):
                    SimpleColorPicker(color: Binding(get: {color.uiColor}, set: {colorChanged($0)}))
                default:
                    EmptyView()
                }
                SimpleButton("square.grid.2x2", action: {openGridTapped(multiPage.currentMarkups())})
                    .accessibilityIdentifier("editor.openGridButton")
                SimpleButton("plus.rectangle.portrait", action: addPageTapped)
                SimpleButton("viewfinder", action: focusModeToggled)
                    .accessibilityIdentifier("editor.enterFocusModeButton")
                SimpleButton("checkmark", action: editModeToggled)
            case .focus:
                Image(systemName: selectedTool == .eraser ? "eraser" : "pencil")
                SimpleButton("arrow.down.right.and.arrow.up.left", action: focusModeToggled)
                    .accessibilityIdentifier("editor.exitFocusModeButton")
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
        selectedTool: .pen(1, .black),
        
        editModeToggled: {},
        focusModeToggled: {},
        
        addPageTapped: {},
        toolSelected: { _ in },
        openGridTapped: { _ in },
        saveAndCloseTapped: { _ in },
        
        pencilDoubleTapped: {},
        bottomOverscrolled: {},
        
        colorChanged: { _ in }
    )
}

