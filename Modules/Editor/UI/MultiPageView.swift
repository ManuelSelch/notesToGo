import SwiftUI
import PaperKit
import PencilKit

// MARK: - SwiftUI Wrapper with VC Reference
struct MultiPageView: UIViewControllerRepresentable {
    let controller: MultiPageController
    
    func makeUIViewController(context: Context) -> MultiPageController {
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MultiPageController, context: Context) { }
}


// MARK: - Multi-Page Container View Controller
class MultiPageController: UIViewController {
    private var toolPicker = PKToolPicker()
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var pageViews: [PageView] = []
    private var pageViewsById: [UUID:PageView] = [:]
    private var isToolPickerVisible = false
    private var lastPage: Int = 0
    
    // layout constants
    private let pageSpacing: CGFloat = 10
    private let horizontalPadding: CGFloat = 0
    
    var document: MultiPageDocument? {
        didSet {
            if isViewLoaded {
                refreshPages()
            }
        }
    }
    
    // Callback when page count changes (for SwiftUI binding)
    var onPageCountChanged: (() -> Void)?
    
    var onPageChanged: (Int) -> Void
    
    init(
        onPageChanged: @escaping (Int) -> Void
    ) {
        self.onPageChanged = onPageChanged
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray5
        
        setupScrollView()
        refreshPages()
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
    
    /// refreshes existing page views with updated data
    private func refreshPages() {
        guard let document = document else { return }
    
        // --- 1. TODO: remove deleted pages
        
        // --- 2. update existing & add new pages
        var lastNewPage: PageView? = nil
        var yOffset: CGFloat = pageSpacing
        for page in document.pages {
            let existingPageView = pageViewsById[page.id]
            let pageView = existingPageView ?? createNewPageView(page)
            
            // track last added page to scroll to this page
            if existingPageView == nil {
                lastNewPage = pageView
            }
            
            // scale markup content if screen rotated
            let oldWidth = pageView.markup?.bounds.width ?? .zero
            let size = displaySize(for: page)
            if oldWidth > 0 && abs(oldWidth - size.width) > 1 {
                let scale = size.width / oldWidth
                pageView.transform(scale, to: size)
            }

            let pageFrame = CGRect(
                x: horizontalPadding,
                y: yOffset,
                width: size.width,
                height: size.height
            )
            pageView.frame = pageFrame
            pageViewsById[page.id] = pageView
            
           
            
           
            yOffset += size.height + pageSpacing
        }
        
        if let lastNewPage = lastNewPage {
            scrollToPage(lastNewPage)
        }
        
        // 3. update scroll view size
        let contentWidth = view.bounds.width
        contentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: yOffset)
        scrollView.contentSize = CGSize(width: contentWidth, height: yOffset)
    }
    
    private func createNewPageView(_ page: Page) -> PageView {
        let size = displaySize(for: page)
        
        let pageFrame = CGRect(
            x: 0, // layout is done in parent method
            y: 0,
            width: size.width,
            height: size.height
        )
       
        let view = PageView(frame: pageFrame)
        view.configure(with: page, toolPicker: toolPicker)
        contentView.addSubview(view)
        
        return view
    }

    /// Calculates the display size for a page, stretching to full available width
    /// and deriving height from the page's own aspect ratio.
    private func displaySize(for page: Page) -> CGSize {
        let availableWidth = view.bounds.width - (horizontalPadding * 2)
        let aspectRatio = page.height / page.width
        let displayHeight = availableWidth * aspectRatio
        return CGSize(width: availableWidth, height: displayHeight)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // rebuild on width change
        if abs(contentView.bounds.width - view.bounds.width) > 1 {
            refreshPages()
        }
    }
    
    private func getCurrentPageIndex() -> Int {
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
        let currentPage = getCurrentPageIndex()
        
        if(lastPage == currentPage) { return }
        
        onPageChanged(currentPage)
        lastPage = currentPage
        
        updateToolPickerForCurrentPage()
    }
    
    private func scrollToPage(_ pageView: PageView, animated: Bool = true) {
        // Scroll to the top of the page (with some spacing above)
        let targetY = max(0, pageView.frame.origin.y - pageSpacing)
        let maxY = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        let clampedY = min(targetY, maxY)
        let targetOffset = CGPoint(x: 0, y: clampedY)
        
        scrollView.setContentOffset(targetOffset, animated: animated)
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
        guard var document = document else { return }
        
        for (index, pageView) in pageViews.enumerated() where document.pages.indices.contains(index) {
            guard let currentMarkup = pageView.currentMarkup() else { continue }
            document.pages[index].markup = currentMarkup
        }
    }
}
