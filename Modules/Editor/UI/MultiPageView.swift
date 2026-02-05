import SwiftUI
import PaperKit
import PencilKit

// MARK: - Multi-Page Container View Controller
class MultiPageController: UIViewController {
    private var toolPicker = PKToolPicker()
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var pageViews: [PageView] = []
    private var isToolPickerVisible = false
    
    // Layout constants
    private let pageSpacing: CGFloat = 10
    private let horizontalPadding: CGFloat = 0
    
    var document: MultiPageDocument? {
        didSet {
            if isViewLoaded {
                rebuildPages()
            }
        }
    }
    
    // Callback when page count changes (for SwiftUI binding)
    var onPageCountChanged: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray5
        
        setupScrollView()
        rebuildPages()
    }
    
    private func setupScrollView() {
        // Single scroll view for everything - only vertical scrolling, no zooming
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.backgroundColor = .systemGray5
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.delegate = self
        
        // Disable zooming - only scroll
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 1.0
        scrollView.bouncesZoom = false
        scrollView.pinchGestureRecognizer?.isEnabled = false
        
        view.addSubview(scrollView)
        
        // Content view that holds all pages
        contentView = UIView()
        contentView.backgroundColor = .clear
        scrollView.addSubview(contentView)
    }
    
    private func rebuildPages() {
        // Clean up existing page views
        for pageView in pageViews {
            pageView.cleanup()
            pageView.removeFromSuperview()
        }
        pageViews.removeAll()
        
        guard let document = document else {
            contentView.frame = .zero
            scrollView.contentSize = .zero
            return
        }
        
        // Calculate page size (fit width with padding)
        let availableWidth = view.bounds.width - (horizontalPadding * 2)
        let pageWidth = availableWidth
        let pageHeight = pageWidth * 1.414 // A4 aspect ratio
        let pageSize = CGSize(width: pageWidth, height: pageHeight)
        
        var yOffset: CGFloat = pageSpacing
        
        // Create page views
        for (index, var page) in document.pages.enumerated() {
            let pageFrame = CGRect(
                x: horizontalPadding,
                y: yOffset,
                width: pageSize.width,
                height: pageSize.height
            )
            
            // Ensure page markup has correct bounds
            let pageBounds = CGRect(origin: .zero, size: pageSize)
            if abs(page.markup.bounds.width - pageBounds.width) > 1 || abs(page.markup.bounds.height - pageBounds.height) > 1 {
                // Update the page's markup with correct bounds
                page.markup = PaperMarkup(bounds: pageBounds)
                document.pages[index] = page
            }
            
            let pageView = PageView(frame: pageFrame)
            pageView.configure(with: page, toolPicker: toolPicker)
            
            contentView.addSubview(pageView)
            pageViews.append(pageView)
            
            yOffset += pageSize.height + pageSpacing
        }
        
        // Update content view and scroll view content size
        let contentHeight = yOffset
        let contentWidth = view.bounds.width
        
        contentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        scrollView.contentSize = CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Only rebuild if width changed significantly (orientation change)
        let currentWidth = view.bounds.width
        if abs(contentView.bounds.width - currentWidth) > 1 {
            rebuildPages()
        }
    }
    
    @objc private func plusButtonPressed(_ button: UIBarButtonItem) {
        guard let currentIndex = document?.currentPageIndex,
              pageViews.indices.contains(currentIndex) else { return }
        
        let insertionVC = MarkupEditViewController(supportedFeatureSet: .latest)
        insertionVC.modalPresentationStyle = .popover
        insertionVC.popoverPresentationController?.barButtonItem = button
        present(insertionVC, animated: true)
    }
    
    // MARK: - Public Methods
    
    func addNewPage(with background: PageBackground = .plain(.white)) {
        guard let document = document else { return }
        
        // Calculate page size
        let pageWidth = view.bounds.width - (horizontalPadding * 2)
        let pageHeight = pageWidth * 1.414
        let pageSize = CGSize(width: pageWidth, height: pageHeight)
        let bounds = CGRect(origin: .zero, size: pageSize)
        
        // Add page to document
        document.addPage(with: bounds, background: background)
        
        // Calculate position for new page
        let newIndex = document.pages.count - 1
        let yOffset: CGFloat = pageSpacing + CGFloat(newIndex) * (pageSize.height + pageSpacing)
        
        let pageFrame = CGRect(
            x: horizontalPadding,
            y: yOffset,
            width: pageSize.width,
            height: pageSize.height
        )
        
        // Create and configure new page view
        let pageView = PageView(frame: pageFrame)
        pageView.configure(with: document.pages[newIndex], toolPicker: toolPicker)
        
        contentView.addSubview(pageView)
        pageViews.append(pageView)
        
        // Update content size
        let newContentHeight = yOffset + pageSize.height + pageSpacing
        contentView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: newContentHeight)
        scrollView.contentSize = CGSize(width: view.bounds.width, height: newContentHeight)
        
        // Scroll to the new page
        scrollToPage(newIndex, animated: true)
        
        onPageCountChanged?()
    }
    
    func deleteCurrentPage() {
        guard let document = document else { return }
        document.removePage(at: document.currentPageIndex)
        rebuildPages()
        onPageCountChanged?()
    }
    
    func setBackground(background: PageBackground, for pageIndex: Int) {
        guard let document = document,
              document.pages.indices.contains(pageIndex) else { return }
        
        document.pages[pageIndex].background = background
        
        // Reconfigure the specific page view
        if pageViews.indices.contains(pageIndex) {
            pageViews[pageIndex].configure(with: document.pages[pageIndex], toolPicker: toolPicker)
        }
    }
    
    func scrollToPage(_ index: Int, animated: Bool = true) {
        guard pageViews.indices.contains(index) else { return }
        
        let pageView = pageViews[index]
        
        // Scroll to the top of the page (with some spacing above)
        let targetY = max(0, pageView.frame.origin.y - pageSpacing)
        let targetOffset = CGPoint(x: 0, y: targetY)
        
        scrollView.setContentOffset(targetOffset, animated: animated)
        
        document?.currentPageIndex = index
    }
    
    func getCurrentPageIndex() -> Int {
        // Determine which page is most visible
        let visibleRect = CGRect(
            origin: scrollView.contentOffset,
            size: scrollView.bounds.size
        )
        let visibleCenter = CGPoint(
            x: visibleRect.midX,
            y: visibleRect.midY
        )
        
        for (index, pageView) in pageViews.enumerated() {
            if pageView.frame.contains(visibleCenter) {
                return index
            }
        }
        
        // Fallback: find page with most overlap
        var maxOverlap: CGFloat = 0
        var maxIndex = 0
        
        for (index, pageView) in pageViews.enumerated() {
            let intersection = visibleRect.intersection(pageView.frame)
            let overlap = intersection.width * intersection.height
            if overlap > maxOverlap {
                maxOverlap = overlap
                maxIndex = index
            }
        }
        
        return maxIndex
    }
}

// MARK: - UIScrollViewDelegate
extension MultiPageController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateCurrentPage()
        }
    }
    
    private func updateCurrentPage() {
        let newIndex = getCurrentPageIndex()
        
        if document?.currentPageIndex != newIndex {
            document?.currentPageIndex = newIndex
            
            // Switch tool picker to new page if visible
            updateToolPickerForCurrentPage()
        }
    }
}


extension MultiPageController {
    func showPencilTools(_ visible: Bool) {
        isToolPickerVisible = visible
        updateToolPickerForCurrentPage()
    }
    
    /// Updates tool picker for the current page based on isToolPickerVisible
    private func updateToolPickerForCurrentPage() {
        guard let document = document,
              pageViews.indices.contains(document.currentPageIndex) else { return }
        
        let currentPageView = pageViews[document.currentPageIndex]
        
        if isToolPickerVisible {
            currentPageView.activate(with: toolPicker)
        } else {
            currentPageView.deactivate(with: toolPicker)
        }
    }
}
