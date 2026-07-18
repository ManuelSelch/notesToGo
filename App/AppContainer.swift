import SwiftUI
import Router
import Dependencies
import Flux

struct AppContainer: View {
    @Dependency(\.router) var router
    
    @ObservedObject var editor = EditorApp().build()
    
    init() {}
    
    var body: some View {
        StackWithSheetRouterView(router, content: { route in
            VStack {
                switch route {
                case let .explorer(route):
                    ExplorerContainer(
                        route: route,
                        openNoteTapped: { editor.dispatch(.openNote($0)) },
                        openQuickNoteTapped: { editor.dispatch(.openQuickNote($0)) }
                    )
                case let .editor(route):
                    EditorContainer(editor, route: route)
                }
            }
        })
    }
}


#Preview {
    AppContainer()
}
