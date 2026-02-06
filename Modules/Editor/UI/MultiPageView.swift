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
    
    /// Calculates the display size for a page, stretching to full available width
    /// and deriving height from the page's own aspect ratio.
    private func displaySize(for page: Page) -> CGSize {
        let availableWidth = view.bounds.width - (horizontalPadding * 2)
        let aspectRatio = page.height / page.width
        let displayHeight = availableWidth * aspectRatio
        return CGSize(width: availableWidth, height: displayHeight)
    }
    
    private func rebuildPages() {
        syncDrawingsToDocument()
        
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
        
        var yOffset: CGFloat = pageSpacing

        for (index, page) in document.pages.enumerated() {
            let size = displaySize(for: page)
            // Scale markup content if display size changed
            let oldWidth = page.markup.bounds.width
            
            if oldWidth > 0 && abs(oldWidth - size.width) > 1 {
                let scale = size.width / oldWidth
                document.pages[index].markup.transformContent(CGAffineTransform(scaleX: scale, y: scale))
                document.pages[index].markup.bounds = CGRect(origin: .zero, size: size)
            }
            
           
            let pageFrame = CGRect(
                x: horizontalPadding,
                y: yOffset,
                width: size.width,
                height: size.height
            )

            let pageView = PageView(frame: pageFrame)
            pageView.configure(with: document.pages[index], toolPicker: toolPicker)

            contentView.addSubview(pageView)
            pageViews.append(pageView)

            yOffset += size.height + pageSpacing
        }

        
        // Update content view and scroll view content size
        let contentWidth = view.bounds.width
        contentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: yOffset)
        scrollView.contentSize = CGSize(width: contentWidth, height: yOffset)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Rebuild on width change (rotation, multitasking resize)
        if abs(contentView.bounds.width - view.bounds.width) > 1 {
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
    
    func pageAdded() {
        guard let document = document else { return }
        
        // calculate page size
        let newIndex = document.pages.count - 1
        let page = document.pages[newIndex]
        let size = displaySize(for: page)
        
        // yOffset = last page view bottom + spacing, or just spacing if first
        let yOffset: CGFloat
        if let lastPageView = pageViews.last {
            yOffset = lastPageView.frame.maxY + pageSpacing
        } else {
            yOffset = pageSpacing
        }
        
        let pageFrame = CGRect(
            x: horizontalPadding,
            y: yOffset,
            width: size.width,
            height: size.height
        )
        
        // Create and configure new page view
        let pageView = PageView(frame: pageFrame)
        pageView.configure(with: document.pages[newIndex], toolPicker: toolPicker)
        
        contentView.addSubview(pageView)
        pageViews.append(pageView)
        
        // Update content size
        let newContentHeight = yOffset + size.height + pageSpacing
        contentView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: newContentHeight)
        scrollView.contentSize = CGSize(width: view.bounds.width, height: newContentHeight)

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
        let maxY = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        let clampedY = min(targetY, maxY)
        let targetOffset = CGPoint(x: 0, y: clampedY)
        
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


extension MultiPageController {
    /// Copies the current PaperMarkup from each PageView back into the document model.
    /// Call this before persisting the document.
    func syncDrawingsToDocument() {
        guard let document = document else { return }
        
        for (index, pageView) in pageViews.enumerated() where document.pages.indices.contains(index) {
            guard let currentMarkup = pageView.currentMarkup() else { continue }
            document.pages[index].markup = currentMarkup
        }
    }
}
