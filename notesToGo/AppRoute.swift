import Foundation
import Router

enum AppRoute: Equatable & Hashable & Identifiable & Codable {
    case explorer
    case editor
    
    var id: Self { self }
}

@MainActor
struct MyRouter {
    static let shared: StackRouter<AppRoute> = .init(root: .explorer)
}
