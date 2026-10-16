import FactoryKit
import Foundation
import Router
import Dependencies

typealias MyRouter = StackWithSheetRouter<AppRoute>
typealias RouteType = Equatable & Hashable & Identifiable & Codable

enum AppRoute: RouteType {
    case explorer(ExplorerRoute)
    case editor(EditorFeature.Route)
    case settings(SettingsFeature.Route)
    
    var id: Self { self }
}

@MainActor
extension Container {
    var router: Factory<MyRouter> {
        self { MyRouter(root: .explorer(.dashboard(path: nil))) }.cached
    }
}

struct RouterKey: DependencyKey {
    static var liveValue: MyRouter = .init(root: .explorer(.dashboard(path: nil)))
}

extension DependencyValues {
    var router: MyRouter { Self[RouterKey.self] }
}
