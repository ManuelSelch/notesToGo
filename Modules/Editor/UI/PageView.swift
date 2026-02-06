import SwiftUI
import PaperKit
import PencilKit

/// UIView that displays background + paper markup for one page
class PageView: UIView {
    private var backgroundImageView: UIImageView!
    private var controller: PaperMarkupViewController?
    
    var markup: PaperMarkup? { controller?.markup }
    
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
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(backgroundImageView)
    }
    
    func configure(with page: Page, toolPicker: PKToolPicker) {
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
        if let patternImage = page.background.patternImage() {
            // Create a view with tiled pattern using
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
        
        toolPicker.addObserver(paperVC)
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
    
    
    func showToolPicker(_ visible: Bool, with toolPicker: PKToolPicker) {
        guard let controller = controller else { return }
        
        toolPicker.setVisible(visible, forFirstResponder: controller)
        
        if(visible) {
            controller.becomeFirstResponder()
        } else {
            controller.resignFirstResponder()
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
