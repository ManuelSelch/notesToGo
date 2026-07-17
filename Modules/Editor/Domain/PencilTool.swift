import Foundation

enum PencilTool: String, Sendable, CaseIterable, Identifiable, Equatable {
    case pen, pencil, marker, eraser, lasso
    var id: String { rawValue }
}
