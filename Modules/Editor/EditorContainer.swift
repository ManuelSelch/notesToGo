import SwiftUI
import PencilKit
import PDFKit
import PhotosUI

struct EditorContainer: View {
    @State var editor = MultiPageEditor()
    @State var showTools = false
    
    init() {
        editor.initialize(MultiPageDocument(
            pageCount: 2,
            pageSize: .init(width: 300, height: 500)
        ))
    }
    
    var body: some View {
        VStack {
            MultiPageView(controller: editor.controller)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading, content: SaveToolbar)
                    ToolbarItem(placement: .topBarTrailing, content: EditToolbar)
                }
                .ignoresSafeArea(.all)
        }
    }
    
    @ViewBuilder
    func EditToolbar() -> some View {
        HStack {
            Button("Add Page") {
                editor.addPage()
            }
            
            Button(showTools ? "Done": "Draw") {
                showTools.toggle()
                editor.showPencilTools(showTools)
            }
        }
    }
    
    @ViewBuilder
    func SaveToolbar() -> some View {
        HStack {
            Button("Save") {
                
            }
        }
    }

}


// MARK: - SwiftUI Wrapper with VC Reference
struct MultiPageView: UIViewControllerRepresentable {
    let controller: MultiPageController
    
    func makeUIViewController(context: Context) -> MultiPageController {
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MultiPageController, context: Context) { }
}
