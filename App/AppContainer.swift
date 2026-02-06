import SwiftUI
import Router
import Dependencies

struct AppContainer: View {
    @Dependency(\.router) var router
    
    init() {}
    
    var body: some View {
        StackWithSheetRouterView(router, content: { route in
            VStack {
                switch route {
                case let .explorer(route):
                    ExplorerContainer(route: route)
                case let .editor(note):
                    EditorContainer(note: note)
                }
            }
        })
    }
}


#Preview {
    AppContainer()
}
