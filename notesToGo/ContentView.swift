import SwiftUI
import PencilKit
import PDFKit

struct ContentView: View {
    @State var data = EditorData()
    @State var showTools = false
    
    var body: some View {
        NavigationStack {
            EditorView(size: .init(width: 350, height: 670), data: data)
                .toolbar {
                    toolbar()
                }
                .ignoresSafeArea(.all)
        }
    }
    
    @ViewBuilder
    func toolbar() -> some View {
        HStack {
            Button("Text") {
                data.insertText(.init(string: "Hello World"), rect: .zero)
            }
            
            Button(showTools ? "Done": "Draw") {
                showTools.toggle()
                data.showPencilTools(showTools)
            }
        }
    }

}


#Preview {
    ContentView()
}
