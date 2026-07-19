import SwiftUI
import Router
import Dependencies
import Flux

let config = EditorConfig()

struct AppContainer: View {
    @Dependency(\.router) var router
    
    @StateObject var explorer = ExplorerApp().build()
    @StateObject var editor = EditorApp().build(editor: config)
    @StateObject var settings = SettingsApp().build(editor: config)
    
    var body: some View {
        StackWithSheetRouterView(router, content: { route in
            VStack {
                switch route {
                case let .explorer(route):
                    ExplorerContainer(
                        explorer, route: route,
                        openNoteTapped: { editor.dispatch(.openNote($0)) },
                        openQuickNoteTapped: { editor.dispatch(.openQuickNote($0)) }
                    )
                case let .editor(route):
                    EditorContainer(editor, route: route)
                case let .settings(route):
                    SettingsContainer(settings, route: route)
                }
            }
        })
    }
}


#Preview {
    AppContainer()
}
