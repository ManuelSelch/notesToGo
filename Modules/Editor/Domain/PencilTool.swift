import Foundation

enum PencilTool: String, CaseIterable, Identifiable, Equatable {
    case pen, pencil, marker, eraser, lasso
    var id: String { rawValue }
}
