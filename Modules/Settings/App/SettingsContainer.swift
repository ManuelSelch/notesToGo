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
                    saveTapped: {
                        editor.dispatch(.penSizeChanged($0.penSize))
                        editor.dispatch(.defaultColorChanged($0.color))
                    },
                    consoleTapped: { router.sheet?.push(.settings(.console))},
                    
                    penSize: editor.state.penSize,
                    color: editor.state.defaultColor.uiColor
                )
            case .console:
                ConsoleView(store: .shared)
            }
            
        }
    }
}
