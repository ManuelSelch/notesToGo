import Foundation

enum PencilTool: Hashable, Sendable, Identifiable, Equatable {
    case pen(_ width: CGFloat)
    case pencil, marker
    case eraser
    case lasso
    
    var id: Self { self }
}
