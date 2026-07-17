import SwiftUI
import PaperKit
import PencilKit
import PDFKit

/// UIView that displays background + paper markup for one page
class PageView: UIView {
    private var backgroundImageView: UIImageView!
    private var controller: PaperMarkupViewController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        clipsToBounds = true
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6
        layer.masksToBounds = false
        
        // Background image view
        backgroundImageView = UIImageView(frame: bounds)
        backgroundImageView.contentMode = .scaleToFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(backgroundImageView)
    }
    
    func configure(with page: Page, pdfPage: PDFPage?) {
        // remove existing paper view controller
        if let existingVC = controller {
            existingVC.willMove(toParent: nil)
            existingVC.view.removeFromSuperview()
            existingVC.removeFromParent()
            controller = nil
        }
        
        // ensure markup bounds match our view bounds
        let pageBounds = CGRect(origin: .zero, size: bounds.size)
        
        // create new PaperMarkup with correct bounds if needed
        let markup: PaperMarkup
        if abs(page.markup.bounds.width - pageBounds.width) > 1 || abs(page.markup.bounds.height - pageBounds.height) > 1 {
            markup = PaperMarkup(bounds: pageBounds)
        } else {
            markup = page.markup
        }
        
        backgroundImageView.image = pdfPage.map { renderPDFPage($0, size: bounds.size) }
        
        // create new paper markup view controller with correct bounds
        let paperVC = PaperMarkupViewController(
            markup: markup,
            supportedFeatureSet: .latest
        )
        
        // parentViewController.addChild(paperVC)
        paperVC.view.frame = bounds
        paperVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        paperVC.view.backgroundColor = .clear
        addSubview(paperVC.view)

        // Disable any internal scroll views in PaperMarkupViewController
        disableInternalScrolling(in: paperVC.view)
        
        // Set content view for PaperKit - this is what shows behind the drawing
        let contentBackgroundView: UIView
        if pdfPage != nil {
            let clearView = UIView(frame: bounds)
            clearView.backgroundColor = .clear
            contentBackgroundView = clearView
        } else if let patternImage = page.background.patternImage() {
            let tiledView = UIView(frame: bounds)
            tiledView.backgroundColor = UIColor(patternImage: patternImage)
            contentBackgroundView = tiledView
        } else {
            let colorView = UIView()
            colorView.backgroundColor = page.background.backgroundColor
            colorView.frame = bounds
            contentBackgroundView = colorView
        }
        paperVC.contentView = contentBackgroundView
        
        controller = paperVC
    }
    
    private func renderPDFPage(_ page: PDFPage, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let pdfBounds = page.bounds(for: .mediaBox)
            let scale = min(size.width / pdfBounds.width, size.height / pdfBounds.height)
            let drawSize = CGSize(width: pdfBounds.width * scale, height: pdfBounds.height * scale)
            let origin = CGPoint(x: (size.width - drawSize.width) / 2, y: (size.height - drawSize.height) / 2)
            
            let cg = context.cgContext
            cg.saveGState()
            cg.translateBy(x: origin.x, y: origin.y + drawSize.height)
            cg.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: cg)
            cg.restoreGState()
        }
    }
    
    public func transform(_ scale: CGFloat, to size: CGSize) {
        // controller?.markup?.transformContent(.identity) // reset to transform relativly to original content
        
        controller?.markup?.transformContent(CGAffineTransform(scaleX: scale, y: scale))
        controller?.markup?.bounds = CGRect(origin: .zero, size: size)
    }
    
    /// Recursively find and disable scroll views within the PaperMarkupViewController
    private func disableInternalScrolling(in view: UIView) {
        for subview in view.subviews {
            if let scrollView = subview as? UIScrollView {
                // Disable scrolling but keep other interactions (like drawing)
                scrollView.isScrollEnabled = false
                scrollView.bounces = false
                scrollView.bouncesZoom = false
                scrollView.minimumZoomScale = 1.0
                scrollView.maximumZoomScale = 1.0
                scrollView.pinchGestureRecognizer?.isEnabled = false
                scrollView.panGestureRecognizer.isEnabled = false
            }
            
            // Continue recursively
            disableInternalScrolling(in: subview)
        }
    }
    
    
    func updateMode(_ mode: EditMode, isCurrentPage: Bool) {
        guard let controller = controller else { return }
        let isActiveDrawingPage = mode.isDrawing && isCurrentPage
        
        controller.view.isUserInteractionEnabled = mode.isDrawing
        
        if(isActiveDrawingPage) {
            controller.becomeFirstResponder()
        } else {
            controller.resignFirstResponder()
        }
    }
    
    func selectTool(_ tool: PencilTool) {
        switch tool {
        case .eraser:
            controller?.drawingTool = PKEraserTool(.bitmap, width: 50)
        case .pen, .pencil, .marker, .lasso:
            controller?.drawingTool = PKInkingTool(.pen, color: .black, width: 5)
        }
    }
    
    func cleanup() {
        guard let controller = controller else { return }
        
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()
        
        self.controller = nil
    }
    
    func currentMarkup() -> PaperMarkup? {
        return controller?.markup
    }
}
