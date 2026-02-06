import SwiftUI
import PencilKit
import PDFKit
import PhotosUI

struct EditorContainer: View {
    @State var editor: Editor
    @State var showTools = false
    
    init(_ note: Note) {
        editor = (try? Editor.load(from: note.markup)) ?? Editor(MultiPageDocument(
            pageCount: 2,
            pageSize: .init(width: 300, height: 500),
            background: .dotted(dotColor: .black, backgroundColor: .white, spacing: 50, dotSize: 2)
        ), fileURL: note.markup)
    }
    
    var body: some View {
        VStack {
            VStack {}
            //MultiPageView(controller: editor.controller)
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
                Task {
                    try await editor.save()
                }
            }
        }
    }

}
