import SwiftUI
import PaperKit

struct EditorView: View {
    let size: CGSize
    let note: Note
    
    @Binding var editor: Editor
    
    var body: some View {
        if let controller = editor.controller {
            PaperControllerView(controller: controller)
        } else {
            ProgressView()
                .onAppear {
                    editor.initializeController(.init(origin: .zero, size: size))
                    Task { await editor.load(from: note.markup) }
                }
        }
    }
}

/// Paper Controller View
fileprivate struct PaperControllerView: UIViewControllerRepresentable {
    let controller: PaperMarkupViewController
    
    func makeUIViewController(context: Context) -> PaperMarkupViewController {
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PaperMarkupViewController, context: Context) {
        
    }
}
