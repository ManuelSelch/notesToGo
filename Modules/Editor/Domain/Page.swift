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

    func duplicated(id: UUID) -> Page {
        Page(id: id, markup: markup, background: background)
    }
    
    static func empty(id: UUID) -> Page {
        Page(
            id: id,
            bounds: .init(x: 0, y: 0, width: 300, height: 500),
            background: .dotted(dotColor: .black, backgroundColor: .white, spacing: 50, dotSize: 2)
        )
    }
    
    static var empty: Page {
        empty(id: UUID())
    }
}
