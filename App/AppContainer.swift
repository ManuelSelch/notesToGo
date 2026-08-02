import SwiftUI
import Router
import Dependencies
import Flux

struct AppContainer: View {
    @Dependency(\.router) var router
    
    @StateObject var explorer = ExplorerApp().build()
    @StateObject var editor = EditorApp().build()
    @StateObject var settings = SettingsApp().build()
    
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
                    EditorContainer(route)
                case let .settings(route):
                    SettingsContainer(route)
                }
            }
        })
        .environmentObject(explorer)
        .environmentObject(editor)
        .environmentObject(settings)
        
    }
}


extension FluxStore {
    
}
