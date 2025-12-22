import SwiftUI
import PencilKit
import PDFKit

struct ContentView: View {
    private static let examplePDFURL = Bundle.main.url(
        forResource: "example",
        withExtension: "pdf"
    )!
    
    @State private var document: PDFDocument? = PDFDocument(url: examplePDFURL)
    
    var body: some View {
        VStack {
            Text("Notes to go")
            
            if let doc = document {
                PDFKitViewWithOverlay(document: doc)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Text("Loading PDF…")
            }
        }
    }
}

