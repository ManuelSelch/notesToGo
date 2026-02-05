import SwiftUI
import PaperKit
import PencilKit

// MARK: - Page Model
struct Page: Identifiable {
    let id = UUID()
    var markup: PaperMarkup
    var backgroundImage: UIImage?
    var backgroundColor: UIColor
    
    init(bounds: CGRect, backgroundImage: UIImage? = nil, backgroundColor: UIColor = .white) {
        self.markup = PaperMarkup(bounds: bounds)
        self.backgroundImage = backgroundImage
        self.backgroundColor = backgroundColor
    }
    
    /// Update markup bounds to match new size
    mutating func updateBounds(_ newBounds: CGRect) {
        // Only recreate if bounds actually changed significantly
        let currentBounds = markup.bounds
        if abs(currentBounds.width - newBounds.width) > 1 || abs(currentBounds.height - newBounds.height) > 1 {
            // Note: This creates a new PaperMarkup - existing drawings would be lost
            // In production, you'd want to transfer the markup data
            markup = PaperMarkup(bounds: newBounds)
        }
    }
}

// MARK: - Document Model
@Observable
class MultiPageDocument {
    var pages: [Page] = []
    var currentPageIndex: Int = 0
    
    var currentPage: Page? {
        guard pages.indices.contains(currentPageIndex) else { return nil }
        return pages[currentPageIndex]
    }
    
    init(pageCount: Int = 1, pageSize: CGSize) {
        for _ in 0..<pageCount {
            pages.append(Page(bounds: CGRect(origin: .zero, size: pageSize)))
        }
    }
    
    func addPage(with bounds: CGRect, backgroundImage: UIImage? = nil) {
        let newPage = Page(bounds: bounds, backgroundImage: backgroundImage)
        pages.append(newPage)
    }
    
    func removePage(at index: Int) {
        guard pages.count > 1, pages.indices.contains(index) else { return }
        pages.remove(at: index)
        if currentPageIndex >= pages.count {
            currentPageIndex = pages.count - 1
        }
    }
}

// MARK: - Page Content View
/// A simple UIView that holds background + paper markup for one page
class PageContentView: UIView {
    
    private var backgroundImageView: UIImageView!
    private var paperViewController: PaperMarkupViewController?
    private weak var parentVC: UIViewController?
    
    var page: Page?
    var featureSet: FeatureSet = .latest
    var toolPicker: PKToolPicker?
    
    var onMarkupChanged: ((PaperMarkup) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = .white
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
    
    func configure(with page: Page, parentViewController: UIViewController, featureSet: FeatureSet, toolPicker: PKToolPicker?) {
        self.page = page
        self.parentVC = parentViewController
        self.featureSet = featureSet
        self.toolPicker = toolPicker
        
        // Update background
        backgroundImageView.image = page.backgroundImage
        backgroundImageView.backgroundColor = page.backgroundColor
        
        // Remove existing paper view controller
        if let existingVC = paperViewController {
            existingVC.willMove(toParent: nil)
            existingVC.view.removeFromSuperview()
            existingVC.removeFromParent()
            paperViewController = nil
        }
        
        // Ensure markup bounds match our view bounds
        let pageBounds = CGRect(origin: .zero, size: bounds.size)
        
        // Create new PaperMarkup with correct bounds if needed
        let markup: PaperMarkup
        if abs(page.markup.bounds.width - pageBounds.width) > 1 || abs(page.markup.bounds.height - pageBounds.height) > 1 {
            markup = PaperMarkup(bounds: pageBounds)
        } else {
            markup = page.markup
        }
        
        // Create new paper markup view controller with correct bounds
        let paperVC = PaperMarkupViewController(
            markup: markup,
            supportedFeatureSet: featureSet
        )
        
        parentViewController.addChild(paperVC)
        paperVC.view.frame = bounds
        paperVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        paperVC.view.backgroundColor = .clear
        addSubview(paperVC.view)
        paperVC.didMove(toParent: parentViewController)
        
        // Disable any internal scroll views in PaperMarkupViewController
        disableInternalScrolling(in: paperVC.view)
        
        // Set content view for background rendering under markup
        if let backgroundImage = page.backgroundImage {
            let templateView = UIImageView(image: backgroundImage)
            templateView.contentMode = .scaleAspectFill
            templateView.frame = bounds
            paperVC.contentView = templateView
        } else {
            let colorView = UIView()
            colorView.backgroundColor = page.backgroundColor
            colorView.frame = bounds
            paperVC.contentView = colorView
        }
        
        // Register with tool picker
        if let toolPicker = toolPicker {
            toolPicker.addObserver(paperVC)
        }
        
        paperViewController = paperVC
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
    
    func makeActive(with toolPicker: PKToolPicker?) {
        guard let paperVC = paperViewController else { return }
        toolPicker?.setVisible(true, forFirstResponder: paperVC)
        paperVC.becomeFirstResponder()
    }
    
    func cleanup() {
        if let existingVC = paperViewController {
            existingVC.willMove(toParent: nil)
            existingVC.view.removeFromSuperview()
            existingVC.removeFromParent()
            paperViewController = nil
        }
    }
}

// MARK: - Multi-Page Container View Controller
class MultiPageContainerViewController: UIViewController {
    
    // Single global scroll view
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    
    // Page views
    private var pageViews: [PageContentView] = []
    
    // Tool picker
    private var toolPicker: PKToolPicker?
    
    // Layout constants
    private let pageSpacing: CGFloat = 30
    private let horizontalPadding: CGFloat = 20
    
    var document: MultiPageDocument? {
        didSet {
            if isViewLoaded {
                rebuildPages()
            }
        }
    }
    
    var featureSet: FeatureSet = {
        var features = FeatureSet.latest
        features.colorMaximumLinearExposure = 4
        return features
    }()
    
    // Callback when page count changes (for SwiftUI binding)
    var onPageCountChanged: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray5
        
        setupScrollView()
        setupToolPicker()
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
    
    private func setupToolPicker() {
        let picker = PKToolPicker()
        picker.colorMaximumLinearExposure = 4
        
        let button = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(plusButtonPressed(_:))
        )
        picker.accessoryItem = button
        
        toolPicker = picker
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
            
            let pageView = PageContentView(frame: pageFrame)
            pageView.configure(
                with: page,
                parentViewController: self,
                featureSet: featureSet,
                toolPicker: toolPicker
            )
            
            contentView.addSubview(pageView)
            pageViews.append(pageView)
            
            yOffset += pageSize.height + pageSpacing
        }
        
        // Update content view and scroll view content size
        let contentHeight = yOffset
        let contentWidth = view.bounds.width
        
        contentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        scrollView.contentSize = CGSize(width: contentWidth, height: contentHeight)
        
        // Activate first page
        if let firstPage = pageViews.first {
            firstPage.makeActive(with: toolPicker)
        }
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
        
        let insertionVC = MarkupEditViewController(supportedFeatureSet: featureSet)
        insertionVC.modalPresentationStyle = .popover
        insertionVC.popoverPresentationController?.barButtonItem = button
        present(insertionVC, animated: true)
    }
    
    // MARK: - Public Methods
    
    func addNewPage(with backgroundImage: UIImage? = nil) {
        guard let document = document else { return }
        
        // Calculate page size
        let pageWidth = view.bounds.width - (horizontalPadding * 2)
        let pageHeight = pageWidth * 1.414
        let pageSize = CGSize(width: pageWidth, height: pageHeight)
        let bounds = CGRect(origin: .zero, size: pageSize)
        
        // Add page to document
        document.addPage(with: bounds, backgroundImage: backgroundImage)
        
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
        let pageView = PageContentView(frame: pageFrame)
        pageView.configure(
            with: document.pages[newIndex],
            parentViewController: self,
            featureSet: featureSet,
            toolPicker: toolPicker
        )
        
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
    
    func setBackground(image: UIImage, for pageIndex: Int) {
        guard let document = document,
              document.pages.indices.contains(pageIndex) else { return }
        
        document.pages[pageIndex].backgroundImage = image
        
        // Reconfigure the specific page view
        if pageViews.indices.contains(pageIndex) {
            pageViews[pageIndex].configure(
                with: document.pages[pageIndex],
                parentViewController: self,
                featureSet: featureSet,
                toolPicker: toolPicker
            )
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
        pageView.makeActive(with: toolPicker)
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
extension MultiPageContainerViewController: UIScrollViewDelegate {
    
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
            
            if pageViews.indices.contains(newIndex) {
                pageViews[newIndex].makeActive(with: toolPicker)
            }
        }
    }
}

// MARK: - SwiftUI Wrapper
struct MultiPagePaperKitView: UIViewControllerRepresentable {
    @Bindable var document: MultiPageDocument
    var onAddPage: (() -> Void)?
    
    func makeUIViewController(context: Context) -> MultiPageContainerViewController {
        let vc = MultiPageContainerViewController()
        vc.document = document
        vc.onPageCountChanged = {
            // Notify SwiftUI of changes
        }
        context.coordinator.containerVC = vc
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MultiPageContainerViewController, context: Context) {
        // Check if pages were added externally and rebuild if needed
        let vcPageCount = uiViewController.document?.pages.count ?? 0
        if vcPageCount != document.pages.count {
            uiViewController.document = document
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: MultiPagePaperKitView
        weak var containerVC: MultiPageContainerViewController?
        
        init(_ parent: MultiPagePaperKitView) {
            self.parent = parent
        }
        
        func addPage(with image: UIImage? = nil) {
            containerVC?.addNewPage(with: image)
        }
        
        func deleteCurrentPage() {
            containerVC?.deleteCurrentPage()
        }
        
        func setBackgroundForCurrentPage(_ image: UIImage) {
            guard let index = containerVC?.document?.currentPageIndex else { return }
            containerVC?.setBackground(image: image, for: index)
        }
    }
}

// MARK: - SwiftUI Content View
struct ContentView: View {
    @State private var document = MultiPageDocument(
        pageCount: 2,
        pageSize: CGSize(width: 768, height: 1024)
    )
    @State private var showingImagePicker = false
    @State private var pageCount = 2
    
    // Reference to the container VC for direct method calls
    @State private var containerVC: MultiPageContainerViewController?
    
    var body: some View {
        VStack {
            MultiPagePaperKitViewWithRef(document: document, containerVC: $containerVC)
                .navigationTitle("Pages: \(pageCount)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            addNewPage()
                        } label: {
                            Label("Add Page", systemImage: "plus.rectangle")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                showingImagePicker = true
                            } label: {
                                Label("Set Background", systemImage: "photo")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                deletePage()
                            } label: {
                                Label("Delete Page", systemImage: "trash")
                            }
                            .disabled(document.pages.count <= 1)
                            
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker { image in
                        if let image = image {
                            setBackgroundForCurrentPage(image)
                        }
                    }
                }
        }
    }
    
    private func addNewPage() {
        // Call directly on the container VC - no view refresh needed
        containerVC?.addNewPage()
        pageCount = document.pages.count
    }
    
    private func deletePage() {
        containerVC?.deleteCurrentPage()
        pageCount = document.pages.count
    }
    
    private func setBackgroundForCurrentPage(_ image: UIImage) {
        guard let index = containerVC?.document?.currentPageIndex else { return }
        containerVC?.setBackground(image: image, for: index)
    }
}

// MARK: - SwiftUI Wrapper with VC Reference
struct MultiPagePaperKitViewWithRef: UIViewControllerRepresentable {
    @Bindable var document: MultiPageDocument
    @Binding var containerVC: MultiPageContainerViewController?
    
    func makeUIViewController(context: Context) -> MultiPageContainerViewController {
        let vc = MultiPageContainerViewController()
        vc.document = document
        
        // Store reference for direct access
        DispatchQueue.main.async {
            containerVC = vc
        }
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MultiPageContainerViewController, context: Context) {
        // Don't update/rebuild unless absolutely necessary
    }
}

// MARK: - Simple Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    var onImagePicked: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var onImagePicked: (UIImage?) -> Void
        
        init(onImagePicked: @escaping (UIImage?) -> Void) {
            self.onImagePicked = onImagePicked
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            onImagePicked(image)
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImagePicked(nil)
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
