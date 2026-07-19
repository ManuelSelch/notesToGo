import Foundation
import SwiftUI
import PDFKit

final class PDFPageBackgroundView: UIView {
    var pdfPage: PDFPage? {
        didSet { setNeedsDisplay() }
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        UIColor.white.setFill()
        context.fill(rect)
        
        guard let pdfPage else { return }
        
        let pdfBounds = pdfPage.bounds(for: .mediaBox)
        let scale = min(bounds.width / pdfBounds.width, bounds.height / pdfBounds.height)
        let drawSize = CGSize(width: pdfBounds.width * scale, height: pdfBounds.height * scale)
        let origin = CGPoint(x: (bounds.width - drawSize.width) / 2, y: (bounds.height - drawSize.height) / 2)
        
        context.saveGState()
        context.translateBy(x: origin.x, y: origin.y + drawSize.height)
        context.scaleBy(x: scale, y: -scale)
        pdfPage.draw(with: .mediaBox, to: context)
        context.restoreGState()
    }
}
