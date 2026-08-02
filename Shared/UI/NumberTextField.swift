import SwiftUI

struct NumberTextField: View {
    var placeholder: String = ""
    @Binding var value: Double
    

    var body: some View {
        TextField(
            placeholder,
            value: $value,
            format: .number.precision(.fractionLength(0...2))
        )
        .keyboardType(.decimalPad)
    }
}

#Preview {
    @Previewable @State var value: Double = 5.0
    
    NumberTextField(
        placeholder: "my value",
        value: $value
    )
}

