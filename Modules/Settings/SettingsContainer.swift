import SwiftUI
import Dependencies
import Router

struct SettingsContainer: View {
    @Dependency(\.router) var router
    
    let route: SettingsFeature.Route
    
    var body: some View {
        VStack {
            switch(route) {
            case .settings:
                SettingsScreen(
                    consoleTapped: { router.sheet?.push(.settings(.console))}
                )
            case .console:
                Text("Console")
            }
            
        }
    }
}
