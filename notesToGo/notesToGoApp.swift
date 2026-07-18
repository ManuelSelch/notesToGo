import SwiftUI
import Combine

@main
struct notesToGoApp: App {
    @StateObject var theme = Theme()
    
    var body: some Scene {
        WindowGroup {
            AppContainer()
                .environmentObject(theme)
                .statusBarHidden(theme.statusBarHidden)
        }
    }
}
