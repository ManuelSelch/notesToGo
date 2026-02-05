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
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PaperMarkupViewController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

fileprivate class Coordinator: NSObject, PaperMarkupViewController.Delegate {
    let parent: PaperControllerView
    var isExpandingCanvas = false
    
    init(_ parent: PaperControllerView) {
        self.parent = parent
    }

    // This is called whenever the user changes the markup
    func paperMarkupViewControllerDidChangeMarkup(_ paperMarkupViewController: PaperMarkupViewController) {
        updateContentSizeIfNeeded()
    }
    
    func updateContentSizeIfNeeded() {
        guard !isExpandingCanvas else { return }

        guard let oldMarkup = parent.controller.markup else { return }

        // Compute new bounds
        let newRect = oldMarkup.bounds.insetBy(dx: 0, dy: 0).union(CGRect(origin: .zero, size: CGSize(
            width: oldMarkup.bounds.width + 100,
            height: oldMarkup.bounds.height + 100
        )))

        isExpandingCanvas = true
        parent.controller.markup?.bounds = newRect
        isExpandingCanvas = false
    }

    // Optional delegate methods
    func paperMarkupViewControllerDidChangeSelection(_ paperMarkupViewController: PaperMarkupViewController) {}
    func paperMarkupViewControllerDidBeginDrawing(_ paperMarkupViewController: PaperMarkupViewController) {}
    func paperMarkupViewControllerDidChangeContentVisibleFrame(_ paperMarkupViewController: PaperMarkupViewController) {}
}
