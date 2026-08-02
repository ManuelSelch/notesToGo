import SwiftUI
import Dependencies
import Router
import Pulse
import PulseUI
import Flux

struct SettingsApp {
    func build() -> FluxStore<SettingsFeature> {
         return .init(
            state: .init(),
            middlewares: [
                LogMiddleware<SettingsFeature>().handle
            ]
        )
    }
}


struct SettingsContainer: View {
    @Dependency(\.router) var router
    @EnvironmentObject var editor: FluxStore<EditorFeature>
    
    let route: SettingsFeature.Route
    
    init(_ route: SettingsFeature.Route) {
        self.route = route
    }
    
    var body: some View {
        VStack {
            switch(route) {
            case .settings:
                SettingsScreen(
                    saveTapped: { editor.dispatch(.defaultToolsChanged($0)) },
                    consoleTapped: { router.sheet?.push(.settings(.console))},
                    
                    tools: editor.state.defaultTools
                )
            case .console:
                ConsoleView(store: .shared)
            }
            
        }
    }
}
