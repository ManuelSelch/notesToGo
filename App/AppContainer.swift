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
                        openNoteTapped: {
                            editor.dispatch(.open($0.markup))
                            editor.dispatch(.enableEditMode)
                            router.stack.push(.editor(.editor))
                        },
                        openQuickNoteTapped: {
                            editor.dispatch(.open($0.markup))
                            editor.dispatch(.enableFocusMode)
                            router.stack.push(.editor(.editor))
                        }
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
