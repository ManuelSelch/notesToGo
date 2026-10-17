import FactoryKit
import Foundation
import Router

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
