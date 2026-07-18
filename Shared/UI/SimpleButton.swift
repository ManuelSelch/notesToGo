import SwiftUI

struct SimpleButton: View {
    let image: String
    let action: () -> Void
    let color: Color?
    
    init(_ image: String, action: @escaping () -> Void, color: Color? = nil) {
        self.image = image
        self.action = action
        self.color = color
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: image)
                .foregroundStyle(color ?? .black)
        }
    }
}
