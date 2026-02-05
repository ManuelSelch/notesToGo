import Foundation
import PaperKit
import PencilKit

/// model to store a single page (markup and background)
struct Page: Identifiable {
    let id = UUID()
    var markup: PaperMarkup
    var background: PageBackground
    
    init(bounds: CGRect, background: PageBackground) {
        self.markup = PaperMarkup(bounds: bounds)
        self.background = background
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
