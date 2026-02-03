import Foundation
import Router

enum AppRoute: Equatable & Hashable & Identifiable & Codable {
    case test
    case explorer(URL?)
    case editor(Note)
    
    var id: String {
        switch self {
        case .test:
            return "test" // stable
        case .explorer(let url):
            return "explorer-\(url?.absoluteString ?? "root")" // unique per URL
        case .editor(let note):
            return "editor-\(note.id)" // unique per note
        }
    }
}

@MainActor
struct MyRouter {
    static let shared: StackRouter<AppRoute> = .init(root: .explorer(nil))
}
