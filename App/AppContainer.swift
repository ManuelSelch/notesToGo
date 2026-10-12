import SwiftUI
import Router
import Dependencies
import Flux
import Combine

@main
struct AppContainer: App {
    @Dependency(\.router) var router
    
    @StateObject var theme = Theme()
    @StateObject var explorer = ExplorerApp().build()
    @StateObject var editor = EditorApp().build()
    @StateObject var settings = SettingsApp().build()
    let preferences = PreferencesCoordinator()
    
    init() {
        #if DEBUG
        do {
            try UITestFixtures.prepare()
        } catch {
            assertionFailure("Could not prepare requested UI-test fixture: \(error)")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
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
            .environmentObject(theme)
            .environmentObject(explorer)
            .environmentObject(editor)
            .environmentObject(settings)
            .statusBarHidden(preferences.statusBarHidden(editor))
            .alert("Couldn’t save note", isPresented: Binding(
                get: { editor.state.saveFailure != nil },
                set: { if !$0 { editor.dispatch(.dismissSaveFailure) } }
            )) {
                Button("Retry") { editor.dispatch(.save([:])) }
                Button("Keep changes", role: .cancel) { editor.dispatch(.dismissSaveFailure) }
            } message: {
                Text(editor.state.saveFailure?.message ?? "")
            }
        }
    }
}
