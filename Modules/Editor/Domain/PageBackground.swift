import Foundation
import SwiftUI

enum PageBackground: Codable, Equatable {
    case plain(CodableColor)
    case dotted(dotColor: CodableColor, backgroundColor: CodableColor, spacing: CGFloat, dotSize: CGFloat)
    case grid(lineColor: CodableColor, backgroundColor: CodableColor, spacing: CGFloat, lineWidth: CGFloat)
    case lined(lineColor: CodableColor, backgroundColor: CodableColor, spacing: CGFloat, lineWidth: CGFloat)
    
    /// Generate a tiled pattern image for this background
    func patternImage() -> UIImage? {
        switch self {
        case .plain:
            return nil
            
        case .dotted(let dotColor, let backgroundColor, let spacing, let dotSize):
            return Self.createDottedPattern(
                dotColor: dotColor.uiColor,
                backgroundColor: backgroundColor.uiColor,
                spacing: spacing,
                dotSize: dotSize
            )
            
        case .grid(let lineColor, let backgroundColor, let spacing, let lineWidth):
            return Self.createGridPattern(
                lineColor: lineColor.uiColor,
                backgroundColor: backgroundColor.uiColor,
                spacing: spacing,
                lineWidth: lineWidth
            )
            
        case .lined(let lineColor, let backgroundColor, let spacing, let lineWidth):
            return Self.createLinedPattern(
                lineColor: lineColor.uiColor,
                backgroundColor: backgroundColor.uiColor,
                spacing: spacing,
                lineWidth: lineWidth
            )
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .plain(let color):
            return color.uiColor
        case .dotted(_, let bg, _, _):
            return bg.uiColor
        case .grid(_, let bg, _, _):
            return bg.uiColor
        case .lined(_, let bg, _, _):
            return bg.uiColor
        }
    }
    
    // MARK: - Pattern Generation
    static func createDottedPattern(
        dotColor: UIColor,
        backgroundColor: UIColor,
        spacing: CGFloat = 20,
        dotSize: CGFloat = 2
    ) -> UIImage {
        let size = CGSize(width: spacing, height: spacing)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Fill background
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw dot in center
            dotColor.setFill()
            let dotRect = CGRect(
                x: (spacing - dotSize) / 2,
                y: (spacing - dotSize) / 2,
                width: dotSize,
                height: dotSize
            )
            context.cgContext.fillEllipse(in: dotRect)
        }
    }
    
    static func createGridPattern(
        lineColor: UIColor,
        backgroundColor: UIColor,
        spacing: CGFloat = 20,
        lineWidth: CGFloat = 0.5
    ) -> UIImage {
        let size = CGSize(width: spacing, height: spacing)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Fill background
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw grid lines
            lineColor.setStroke()
            context.cgContext.setLineWidth(lineWidth)
            
            // Vertical line (right edge)
            context.cgContext.move(to: CGPoint(x: spacing - lineWidth/2, y: 0))
            context.cgContext.addLine(to: CGPoint(x: spacing - lineWidth/2, y: spacing))
            
            // Horizontal line (bottom edge)
            context.cgContext.move(to: CGPoint(x: 0, y: spacing - lineWidth/2))
            context.cgContext.addLine(to: CGPoint(x: spacing, y: spacing - lineWidth/2))
            
            context.cgContext.strokePath()
        }
    }
    
    static func createLinedPattern(
        lineColor: UIColor,
        backgroundColor: UIColor,
        spacing: CGFloat = 24,
        lineWidth: CGFloat = 0.5
    ) -> UIImage {
        let size = CGSize(width: 10, height: spacing) // Width doesn't matter for horizontal lines
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Fill background
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Draw horizontal line at bottom
            lineColor.setStroke()
            context.cgContext.setLineWidth(lineWidth)
            context.cgContext.move(to: CGPoint(x: 0, y: spacing - lineWidth/2))
            context.cgContext.addLine(to: CGPoint(x: size.width, y: spacing - lineWidth/2))
            context.cgContext.strokePath()
        }
    }
}
