import Foundation
import PencilKit
import PaperKit

@Observable
class Editor {
    var controller: PaperMarkupViewController?
    var markup: PaperMarkup?
    let toolPicker = PKToolPicker()
    
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
    
    /// markup editing methods
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
    
    
    /// pencil
    func showPencilTools(_ isVisible: Bool) {
        guard let controller else { return }
        
        toolPicker.addObserver(controller)
        toolPicker.setVisible(isVisible, forFirstResponder: controller.view)
        
        if isVisible {
            controller.view.becomeFirstResponder()
        }
    }
    
    /// updating controller
    func refreshController() {
        controller?.markup = markup
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
