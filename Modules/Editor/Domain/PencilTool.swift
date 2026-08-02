import Foundation

enum PencilTool: Hashable, Sendable, Identifiable, Equatable {
    case pen(_ width: CGFloat, _ color: CodableColor)
    case pencil, marker
    case eraser
    case lasso
    
    var id: Self { self }
}
