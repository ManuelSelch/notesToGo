import SwiftUI

struct SettingsScreen: View {
    let consoleTapped: () -> Void
    
    var body: some View {
        Form {
            Section("Debug") {
                Button("Console", action: consoleTapped)
            }
        }
    }
}

#Preview {
    SettingsScreen(
        consoleTapped: {}
    )
}
