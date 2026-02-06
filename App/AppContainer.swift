import SwiftUI
import Router
import Dependencies

struct AppContainer: View {
    @Dependency(\.router) var router
    
    init() {
        DependencyValues.setMode(.mock) // TODO: infra not implemented yet
    }
    
    var body: some View {
        StackWithSheetRouterView(router, content: { route in
            VStack {
                switch route {
                case let .explorer(route):
                    ExplorerContainer(route: route)
                case let .editor(note):
                    EditorContainer_v2(note: note)
                }
            }
        })
    }
}


#Preview {
    AppContainer()
}
