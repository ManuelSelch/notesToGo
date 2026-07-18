import SwiftUI
import Dependencies
import Router
import Pulse
import PulseUI
import Flux

struct SettingsApp {
    func build(editor: EditorConfig) -> FluxStore<SettingsFeature> {
         return .init(
            state: .init(),
            middlewares: [
                SettingsMiddleware(editor: editor).handle,
                LogMiddleware<SettingsFeature>().handle
            ]
        )
    }
}

struct SettingsContainer: View {
    @Dependency(\.router) var router
    @ObservedObject var store: FluxStore<SettingsFeature>
    
    let route: SettingsFeature.Route
    
    init(_ store: FluxStore<SettingsFeature>, route: SettingsFeature.Route) {
        self.store = store
        self.route = route
    }
    
    var body: some View {
        VStack {
            switch(route) {
            case .settings:
                SettingsScreen(
                    penSizeChanged: { store.dispatch(.penSizeChanged($0)) },
                    consoleTapped: { router.sheet?.push(.settings(.console))}
                )
            case .console:
                ConsoleView(store: .shared)
            }
            
        }
    }
}
