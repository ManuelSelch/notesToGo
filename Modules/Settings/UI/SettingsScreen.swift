import SwiftUI

struct SettingsDTO {
    var penSize: CGFloat
    var color: CodableColor
}

struct SettingsScreen: View {
    let saveTapped: (SettingsDTO) -> Void
    let consoleTapped: () -> Void
    
    @State var penSize: Double
    @State var color: UIColor

    var body: some View {
        Form {
            Section("Editor") {
                NumberTextField(placeholder: "Pen Size", value: $penSize)
                
                SimpleColorPicker(color: $color)
                
                Button("Save", action: { saveTapped(.init(penSize: penSize, color: CodableColor(color))) })
            }
            
            Section("Debug") {
                Button("Console", action: consoleTapped)
            }
        }
    }
}

#Preview {
    SettingsScreen(
        saveTapped: { _ in },
        consoleTapped: {},
        
        penSize: 5,
        color: .black
    )
}
