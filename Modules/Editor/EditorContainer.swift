import SwiftUI
import PencilKit
import PDFKit
import PhotosUI

struct EditorContainer: View {
    @State var editor = Editor()
    @State var showTools = false
    @State var showImagePicker = false
    @State var photoItem: PhotosPickerItem?
    
    let note: Note
    
    var body: some View {
        VStack {
            EditorView(size: .init(width: 650, height: 670), note: note, editor: $editor)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading, content: SaveToolbar)
                    ToolbarItem(placement: .topBarTrailing, content: EditToolbar)
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
    func EditToolbar() -> some View {
        HStack {
            Button("Text") {
                editor.insertText(.init(string: "Hello World", attributes: [.font: UIFont.systemFont(ofSize: 18)]), rect: .init(x: 100, y: 100, width: 200, height: 50))
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
    func SaveToolbar() -> some View {
        HStack {
            Button("Save") {
                Task {
                    await editor.save(to: note.markup)
                }
            }
        }
    }

}
