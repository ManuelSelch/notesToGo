import Foundation
import PaperKit
import PencilKit

/// model to store a single page (markup and background)
struct Page: Identifiable, Equatable {
    let id: UUID
    var markup: PaperMarkup
    var background: PageBackground
    
    var width: CGFloat { markup.bounds.width }
    var height: CGFloat { markup.bounds.height }
    
    init(id: UUID = UUID(), bounds: CGRect, background: PageBackground) {
        self.id = id
        self.markup = PaperMarkup(bounds: bounds)
        self.background = background
    }
    
    init(id: UUID = UUID(), markup: PaperMarkup, background: PageBackground) {
        self.id = id
        self.markup = markup
        self.background = background
    }

    func duplicated() -> Page {
        Page(markup: markup, background: background)
    }
    
    static var empty: Page {
        return Page(
           bounds: .init(x: 0, y: 0, width: 300, height: 500),
           background: .dotted(dotColor: .black, backgroundColor: .white, spacing: 50, dotSize: 2)
       )
    }
}
