import Foundation
import PencilKit
import PaperKit
import PDFKit

@Observable
class PageEditor {
    var controller: PaperMarkupViewController?
    let toolPicker = PKToolPicker()
    
    // MARK: - controller
    func initializeController(_ rect: CGRect) {
        guard controller == nil else { return } // create controller only once
        
        let controller = PaperMarkupViewController(supportedFeatureSet: .latest)
        controller.markup = PaperMarkup(bounds: rect)
        controller.zoomRange = 0.8...1.5
        
        self.controller = controller
    }
    
    func refreshController() {
        // controller?.markup = markup
    }
    
    // MARK: - markup editing methods
    func insertText(_ text: NSAttributedString, rect: CGRect = .zero) {
        controller?.markup?.insertNewTextbox(attributedText: text, frame: rect)
        refreshController()
    }
    
    func insertImage(_ image: UIImage, rect: CGRect = .zero) {
        guard let cgImage = image.cgImage else { return }
        
        controller?.markup?.insertNewImage(cgImage, frame: rect)
        refreshController()
    }
    
    func insertShape(_ type: ShapeConfiguration, rect: CGRect = .zero) {
        controller?.markup?.insertNewShape(configuration: type, frame: rect)
        refreshController()
    }
    
    /// show or hide native pencil tools
    func showPencilTools(_ isVisible: Bool) {
        guard let controller else { return }
        
        toolPicker.addObserver(controller)
        toolPicker.setVisible(isVisible, forFirstResponder: controller.view)
        
        if isVisible {
            controller.view.becomeFirstResponder()
        }
    }
    
    // MARK: - export
    /// saves editable markup to url
    func save(to url: URL) async {
        guard let markup = controller?.markup else { return }
        
        do {
            let data = try await markup.dataRepresentation()
            try data.write(to: url)
        } catch {
            
        }
    }
    
    /// loads editable markup from url
    func load(from url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            let markup = try PaperMarkup(dataRepresentation: data)
            controller?.markup = markup
        } catch {
            
        }
    }
}

/// calculating center rect
extension NSAttributedString {
    func centerRect(in rect: CGRect) -> CGRect {
        let textSize = self.size()
        let textCenter = CGPoint(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2
        )
        
        return CGRect(origin: textCenter, size: textSize)
    }
}
