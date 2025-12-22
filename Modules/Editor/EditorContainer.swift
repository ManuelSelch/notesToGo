import SwiftUI
import PencilKit
import PDFKit
import PhotosUI

struct EditorContainer: View {
    @State var editor = Editor()
    @State var showTools = false
    @State var showImagePicker = false
    @State var photoItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            EditorView(size: .init(width: 350, height: 670), editor: $editor)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading, content: saveToolbar)
                    ToolbarItem(placement: .topBarTrailing, content: editToolbar)
                }
                .ignoresSafeArea(.all)
        }
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) {
            guard let photoItem else { return }
            
            Task {
                guard let data = try? await photoItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data)
                      else { return }
                
                editor.insertImage(image, rect: .init(origin: .zero, size: .init(width: 100, height: 100)))
                
                self.photoItem = nil
                
            }
        }
    }
    
    @ViewBuilder
    func editToolbar() -> some View {
        HStack {
            Button("Text") {
                editor.insertText(.init(string: "Hello World"))
            }
            
            Button(showTools ? "Done": "Draw") {
                showTools.toggle()
                editor.showPencilTools(showTools)
            }
            
            Button("Image") {
                showImagePicker.toggle()
            }
        }
    }
    
    @ViewBuilder
    func saveToolbar() -> some View {
        HStack {
            Button("Save") {
                editor.insertText(.init(string: "Hello World"))
            }
        }
    }

}


#Preview {
    EditorContainer()
}
