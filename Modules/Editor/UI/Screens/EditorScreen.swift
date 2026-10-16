import SwiftUI
import PaperKit
import PDFKit

struct EditorScreen: View {
    @State private var multiPage = MultiPageController()
    @EnvironmentObject var theme: Theme
    
    let document: MultiPageDocument?
    let pdf: PDFDocument?
    let mode: EditMode
    let tools: [PencilTool]
    let selectedTool: PencilTool
    let canSave: Bool
    let isSaving: Bool
    
    let editModeToggled: () -> Void
    let focusModeToggled: () -> Void
    
    let addPageTapped: () -> Void
    let toolSelected: (PencilTool) -> Void
    let contentChanged: (UUID) -> Void
    let saveTapped: ([UUID: PaperMarkup]) -> Void
    let openGridTapped: ([UUID: PaperMarkup]) -> Void
    let saveAndCloseTapped: ([UUID: PaperMarkup]) -> Void
    
    let pencilDoubleTapped: () -> Void
    let bottomOverscrolled: () -> Void
    
    var body: some View {
        MultiPageView(controller: multiPage, isInteractionEnabled: !isSaving)
            .navigationBarBackButtonHidden() // hide native backup button to be able to save note when user clicks back
            .ignoresSafeArea(.all)
            .onAppear {
                theme.statusBarHidden = (mode == .focus)
            }
            .toolbar {
                if mode != .focus {
                    ToolbarItem(placement: .topBarLeading) { SaveToolbar() }
                }                                                                                                                                                   
                ToolbarItem(placement: .principal) { PenToolbar().disabled(isSaving) }
                ToolbarItem(placement: .topBarTrailing) { EditToolbar().disabled(isSaving) }
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
        multiPage.onCanvasChanged = contentChanged
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
                .disabled(isSaving)
            EditorSaveButton(canSave: canSave, isSaving: isSaving) {
                saveTapped(multiPage.currentMarkups())
            }
        }
    }
    
    @ViewBuilder
    func PenToolbar() -> some View {
        HStack(spacing: 20) {
            if mode == .write {
                ForEach(tools) { tool in
                    SimpleButton(
                        tool.symbol, action: { toolSelected(tool) },
                        color: selectedTool == tool ? .blue : .black
                    )
                }
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
                case let .pen(width, color):
                    SimpleColorPicker(color: Binding(get: {color.uiColor}, set: {toolSelected(.pen(width, CodableColor($0)))}))
                default:
                    EmptyView()
                }
                SimpleButton("square.grid.2x2", action: {openGridTapped(multiPage.currentMarkups())})
                    .accessibilityIdentifier("editor.openGridButton")
                SimpleButton("plus.rectangle.portrait", action: addPageTapped)
                    .accessibilityIdentifier("editor.addPageButton")
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
        tools: [.pen(1, .black), .eraser, .lasso, .marker],
        selectedTool: .pen(1, .black),
        canSave: false,
        isSaving: false,
        
        editModeToggled: {},
        focusModeToggled: {},
        
        addPageTapped: {},
        toolSelected: { _ in },
        contentChanged: { _ in },
        saveTapped: { _ in },
        openGridTapped: { _ in },
        saveAndCloseTapped: { _ in },
        
        pencilDoubleTapped: {},
        bottomOverscrolled: {}
    )
}

