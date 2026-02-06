import Foundation
import Router
import Dependencies

typealias MyRouter = StackWithSheetRouter<AppRoute>
typealias RouteType = Equatable & Hashable & Identifiable & Codable

enum AppRoute: RouteType {
    case explorer(ExplorerRoute)
    case editor(EditorFeature.Route)
    
    var id: Self { self }
}

struct RouterKey: DependencyKey {
    static var liveValue: MyRouter = .init(root: .explorer(.dashboard(path: nil)))
}

extension DependencyValues {
    var router: MyRouter { Self[RouterKey.self] }
}
