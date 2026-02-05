import Foundation
import PaperKit
import PencilKit

/// model to store a single page (markup and background)
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
