import SwiftUI

struct SettingsScreen: View {
    let penSizeChanged: (CGFloat) -> Void
    let consoleTapped: () -> Void
    
    @State var penSize = ""
    
    var body: some View {
        Form {
            Section("Editor") {
                TextField("Pen Size", text: $penSize)
                    .keyboardType(.numberPad)
                
                Button("Save", action: { penSizeChanged(5) })
            }
            
            Section("Debug") {
                Button("Console", action: consoleTapped)
            }
        }
    }
}

#Preview {
    SettingsScreen(
        penSizeChanged: { _ in },
        consoleTapped: {}
    )
}
