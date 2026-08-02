import SwiftUI

struct SettingsScreen: View {
    let saveTapped: ([PencilTool]) -> Void
    let consoleTapped: () -> Void
    
    @State var tools: [PencilTool]

    var body: some View {
        Form {
            Section("Editor") {
                ForEach(tools.indices, id: \.self) { index in
                   ToolSettingsRow(tool: $tools[index])
                }
                
                Button("Save", action: { saveTapped(tools)})
            }
            
            Section("Debug") {
                Button("Console", action: consoleTapped)
            }
        }
    }
}

struct ToolSettingsRow: View {
       @Binding var tool: PencilTool
                                                                                                                                                                                                                     
       var body: some View {
           HStack {
               Image(systemName: tool.symbol)
                                                                                                                                                                                                                     
               Spacer()
                                                                                                                                                                                                                     
               switch tool {
               case let .pen(width, toolColor):
                   HStack {
                       NumberTextField(
                           placeholder: "Pen Size",
                           value: Binding(
                               get: { Double(width) },
                               set: {
                                   tool = .pen(
                                       CGFloat($0),
                                       toolColor
                                   )
                               }
                           )
                       )
                       .frame(width: 100)
                                                                                                                                                                                                                     
                       SimpleColorPicker(
                           color: Binding(
                               get: { toolColor.uiColor },
                               set: {
                                   tool = .pen(
                                       width,
                                       CodableColor($0)
                                   )
                               }
                           )
                       )
                   }
                                                                                                                                                                                                                     
               case .pencil:
                   Text("Pencil")
                                                                                                                                                                                                                     
               case .eraser:
                   Text("Eraser")
                                                                                                                                                                                                                     
               case .lasso:
                   Text("Lasso")
                                                                                                                                                                                                                     
               case .marker:
                   Text("Marker")
               }
           }
       }
}

#Preview {
    SettingsScreen(
        saveTapped: { _ in },
        consoleTapped: {},
        tools: [.pen(1, .black), .eraser, .lasso, .marker]
    )
}
