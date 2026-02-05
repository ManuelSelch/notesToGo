import SwiftUI
import PaperKit
import PencilKit


/// document that stores multiple pages
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
