import Foundation
import PencilKit
import PaperKit
import PDFKit

@Observable
class Editor {
    var controller: PaperMarkupViewController?
    var markup: PaperMarkup?
    let toolPicker = PKToolPicker()
    
    // MARK: - controller
    func initializeController(_ rect: CGRect) {
        let controller = PaperMarkupViewController(supportedFeatureSet: .latest)
        let markup = PaperMarkup(bounds: rect)
        
        if let existingController = self.controller {
            existingController.markup = markup
            self.markup = markup
        } else {
            self.markup = markup
            self.controller = controller
            self.controller?.markup = markup
            self.controller?.zoomRange = 0.8...1.5
        }
    }
    
    func refreshController() {
        controller?.markup = markup
    }
    
    // MARK: - markup editing methods
    func insertText(_ text: NSAttributedString, rect: CGRect = .zero) {
        markup?.insertNewTextbox(attributedText: text, frame: rect)
        refreshController()
    }
    
    func insertImage(_ image: UIImage, rect: CGRect = .zero) {
        guard let cgImage = image.cgImage else { return }
        
        markup?.insertNewImage(cgImage, frame: rect)
        refreshController()
    }
    
    func insertShape(_ type: ShapeConfiguration, rect: CGRect = .zero) {
        markup?.insertNewShape(configuration: type, frame: rect)
        refreshController()
    }
    
    func showPencilTools(_ isVisible: Bool) {
        guard let controller else { return }
        
        toolPicker.addObserver(controller)
        toolPicker.setVisible(isVisible, forFirstResponder: controller.view)
        
        if isVisible {
            controller.view.becomeFirstResponder()
        }
    }
    
    // MARK: - export
    
    // saves editable markup to url
    func save(to url: URL) async {
        guard let markup else { return }
        
        do {
            let data = try await markup.dataRepresentation()
            try data.write(to: url)
        } catch {
            
        }
    }
    
    // loads editable markup from url
    func load(from url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            let markup = try PaperMarkup(dataRepresentation: data)
            self.markup = markup
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
