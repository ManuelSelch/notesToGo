import SwiftUI

struct CreateItemSheet: View {
    let title: String
    let placeholder: String
    let buttonTitle: String
    @Binding var name: String
    let locationName: String?
    let onCancel: () -> Void
    let onCreate: () -> Void
    
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField(placeholder, text: $name)
                
                if let locationName {
                    LabeledContent("Location", value: locationName)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(buttonTitle, action: onCreate)
                        .disabled(trimmedName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
