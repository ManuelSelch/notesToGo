import SwiftUI
import Combine

final class Theme: ObservableObject {
    @Published var statusBarHidden = false
}

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
