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
                    Button(showTools ? "Hide": "Show") {
                        showTools.toggle()
                        data.showPencilTools(showTools)
                    }
                }
        }
    }
}

