import Foundation

nonisolated enum EditMode: Sendable {
    case read
    case write
    case focus
    
    var isDrawing: Bool {
        return self != .read
    }
    
    var isToolbarVisible: Bool {
        return self == .write
    }
}
