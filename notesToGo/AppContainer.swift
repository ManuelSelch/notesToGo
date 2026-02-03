import SwiftUI
import Router
import Dependencies

struct AppContainer: View {
    @Dependency(\.router) var router
    
    var body: some View {
        StackWithSheetRouterView(router, content: { route in
            VStack {
                switch route {
                case let .explorer(route):
                    ExplorerContainer(route: route)
                case .editor:
                    EditorContainer()
                }
            }
        })
    }
}


#Preview {
    AppContainer()
}
