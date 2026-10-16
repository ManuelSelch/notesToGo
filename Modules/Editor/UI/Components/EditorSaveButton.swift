import SwiftUI

/// Rendering only: the feature owns enablement, operation state and saving.
struct EditorSaveButton: View {
    let canSave: Bool
    let isSaving: Bool
    let saveTapped: () -> Void

    var body: some View {
        Button(action: saveTapped) {
            Group {
                if isSaving {
                    ProgressView()
                        .accessibilityIdentifier("editor.saveProgress")
                } else {
                    Image(systemName: "square.and.arrow.down")
                }
            }
            .frame(width: 24, height: 24)
        }
        .disabled(!canSave || isSaving)
        .accessibilityLabel(isSaving ? "Saving" : "Save")
        .accessibilityIdentifier("editor.saveButton")
    }
}
