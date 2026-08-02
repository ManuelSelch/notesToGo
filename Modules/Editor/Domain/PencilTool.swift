import Foundation
import PencilKit

enum PencilTool: Hashable, Sendable, Identifiable, Equatable {
    case pen(_ width: CGFloat, _ color: CodableColor)
    case pencil, marker
    case eraser
    case lasso
    
    var id: Self { self }
}

extension PencilTool {
    var tool: PKTool {
        switch self {
        case .eraser:                   PKEraserTool(.bitmap, width: 50)
        case let .pen(width, color):    PKInkingTool(.monoline, color: color.uiColor, width: width)
        case .pencil:                   PKInkingTool(.monoline, color: .black, width: 1)
        case .lasso:                    PKLassoTool()
        case .marker:                   PKInkingTool(.monoline, color: UIColor.systemYellow.withAlphaComponent(0.5), width: 10)
        }
    }
    
    var symbol: String {
        switch(self) {
        case .pen, .pencil: "pencil"
        case .eraser:       "eraser"
        case .lasso:        "lasso"
        case .marker:       "highlighter"
        }
    }
}
