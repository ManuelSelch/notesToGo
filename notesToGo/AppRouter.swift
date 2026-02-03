import Foundation
import Router
import Dependencies

typealias MyRouter = StackRouter<AppRoute>

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

struct RouterKey: DependencyKey {
    static var liveValue: MyRouter = .init(root: .explorer(nil))
}

extension DependencyValues {
    var router: MyRouter { Self[RouterKey.self] }
}
