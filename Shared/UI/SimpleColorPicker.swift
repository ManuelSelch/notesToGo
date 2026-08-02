import SwiftUI

struct SimpleColorPicker: View {
       @Binding var color: UIColor
                                                                                                                                                                                                                     
       private let colors: [UIColor] = [
           .systemRed,
           .systemOrange,
           .systemYellow,
           .systemGreen,
           .systemBlue
       ]
                                                                                                                                                                                                                     
       var body: some View {
           HStack(spacing: 12) {
               ForEach(colors.indices, id: \.self) { index in
                   let candidate = colors[index]
                   let isSelected = color.isEqual(candidate)
                                                                                                                                                                                                                     
                   Button {
                       color = candidate
                   } label: {
                       Circle()
                           .fill(Color(uiColor: candidate))
                           .frame(width: 32, height: 32)
                           .overlay {
                               Circle()
                                   .stroke(
                                       isSelected ? Color.primary : .clear,
                                       lineWidth: 3
                                   )
                                   .padding(-4)
                           }
                   }
                   .buttonStyle(.plain)
                   .accessibilityLabel("Select color")
                   .accessibilityAddTraits(isSelected ? .isSelected : [])
               }
           }
       }
}

#Preview {
    SimpleColorPicker(
        color: .constant(.red)
    )
}
