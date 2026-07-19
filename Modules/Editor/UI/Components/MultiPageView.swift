import SwiftUI
import PaperKit
import PencilKit
import PDFKit

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
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private lazy var pencilInteraction = UIPencilInteraction(delegate: self)
    
    // layout constants
    private let pageSpacing: CGFloat = 10
    private let horizontalPadding: CGFloat = 0
    
    private var pageViewsById: [UUID:PageView] = [:]
    /// last visible page (changes when scrolling)
    private var currentPage: UUID? = nil
    private var didTriggerBottomOverscroll = false
    private var shouldScrollToNewPageAfterRebuild = false
    
    var onPageChanged: ((UUID) -> Void)?
    var onPencilDoubleTap: (() -> Void)?
    var onScreenWidthChanged: (() -> Void)?
    var onBottomOverscrolled: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray5
        view.addInteraction(pencilInteraction)
        setupScrollView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // rebuild on width change
        if abs(contentView.bounds.width - view.bounds.width) > 1 {
            onScreenWidthChanged?()
        }
    }
}


// MARK: build pages
extension MultiPageController {
    /// refreshes existing page views with updated data (after document was set or width changed)
    func rebuildPages(_ document: MultiPageDocument, _ pdf: PDFDocument?) {
        // --- 1. remove deleted/stale pages
        let validIDs = Set(document.pages.map(\.id))
        let staleIDs = pageViewsById.keys.filter { !validIDs.contains($0) }
        for id in staleIDs {
            pageViewsById[id]?.cleanup()
            pageViewsById[id]?.removeFromSuperview()
            pageViewsById.removeValue(forKey: id)
        }
        
        // --- 2. update existing & add new pages
        var lastNewPage: PageView? = nil
        var yOffset: CGFloat = pageSpacing
        for (index, page) in document.pages.enumerated() {
            let existingPageView = pageViewsById[page.id]
            let pageView = existingPageView ?? createNewPageView(page, pdf, pageIndex: index)
            
            // track last added page to scroll to this page
            if existingPageView == nil {
                lastNewPage = pageView
            }
            
            // scale markup content if screen rotated
            let oldWidth = pageView.currentMarkup()?.bounds.width ?? .zero
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
            
            // increase page offset
            yOffset += size.height + pageSpacing
        }
        
        // 3. update scroll view size
        let contentWidth = view.bounds.width
        contentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: yOffset)
        scrollView.contentSize = CGSize(width: contentWidth, height: yOffset)
        
        if shouldScrollToNewPageAfterRebuild, let lastNewPage = lastNewPage {
            scrollToPage(lastNewPage, animated: false, alignToTopEdge: true)
            shouldScrollToNewPageAfterRebuild = false
        } else if let lastNewPage = lastNewPage {
            scrollToPage(lastNewPage)
        }
        
        reportVisiblePage()
    }
    
    private func createNewPageView(_ page: Page, _ pdf: PDFDocument?, pageIndex: Int) -> PageView {
        let size = displaySize(for: page)
        
        let pageFrame = CGRect(
            x: 0, // layout is done in parent method
            y: 0,
            width: size.width,
            height: size.height
        )
       
        let view = PageView(frame: pageFrame)
        view.configure(with: page, pdfPage: pdf?.page(at: pageIndex), parentViewController: self)
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
}

// MARK: - page scrolling
extension MultiPageController: UIScrollViewDelegate {
    private func setupScrollView() {
        // Single scroll view for everything - only vertical scrolling, no zooming
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.backgroundColor = .systemGray5
        scrollView.accessibilityIdentifier = "editor.pagesScrollView"
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
        contentView.accessibilityIdentifier = "editor.pagesContentView"
        scrollView.addSubview(contentView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
       reportVisiblePage()
       detectBottomOverscroll()
    }
    
    private func reportVisiblePage() {
        guard let currentPage = getCurrentPage() else { return }
        if(self.currentPage == currentPage) { return }
        
        self.currentPage = currentPage
        onPageChanged?(currentPage)
    }
    
    private func getCurrentPage() -> UUID? {
        // determine which page is most visible
        let visibleRect = CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)
        let visibleCenter = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        for (id, pageView) in pageViewsById {
            if pageView.frame.contains(visibleCenter) {
                return id
            }
        }
        
        return nil
    }
    
    private func detectBottomOverscroll() {
        let threshold: CGFloat = 200
        let overscroll = scrollView.contentOffset.y + scrollView.bounds.height - scrollView.contentSize.height
        
        if overscroll > threshold {
            guard !didTriggerBottomOverscroll else { return }
            didTriggerBottomOverscroll = true
            shouldScrollToNewPageAfterRebuild = true
            onBottomOverscrolled?()
        } else {
            didTriggerBottomOverscroll = false
        }
    }
    
    private func scrollToPage(_ pageView: PageView, animated: Bool = true, alignToTopEdge: Bool = false) {
        let targetY = max(0, alignToTopEdge ? pageView.frame.origin.y : pageView.frame.origin.y - pageSpacing)
        let maxY = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        let clampedY = min(targetY, maxY)
        let targetOffset = CGPoint(x: 0, y: clampedY)
        
        scrollView.setContentOffset(targetOffset, animated: animated)
    }
}

// MARK: - mode & tool
extension MultiPageController {
    func updateMode(_ mode: EditMode) {
        for (id, pageView) in self.pageViewsById {
            pageView.updateMode(mode, isCurrentPage: currentPage == id)
        }
    }
    
    func selectTool(_ tool: PencilTool) {
        guard let currentPage else { return }
        pageViewsById[currentPage]?.selectTool(tool)
    }
}

// MARK: - markup
extension MultiPageController {
    /// returns current markups edited by user
    func currentMarkups() -> [UUID: PaperMarkup] {
        var markups: [UUID: PaperMarkup] = [:]
        
        for (id, pageView) in pageViewsById {
            guard let pageMarkup = pageView.currentMarkup() else { continue }
            markups[id] = pageMarkup
        }
        
        return markups
    }
}

// MARK: - pencil interaction
extension MultiPageController: UIPencilInteractionDelegate {
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        onPencilDoubleTap?()
    }
    
    @available(iOS 17.5, *)
    func pencilInteraction(_ interaction: UIPencilInteraction, didReceiveTap tap: UIPencilInteraction.Tap) {
        onPencilDoubleTap?()
    }
}
