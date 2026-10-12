import SwiftUI

struct EditorLoadErrorView: View {
    let message: String
    let retryTapped: () -> Void
    let backTapped: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Couldn’t open note", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Retry", action: retryTapped)
                .accessibilityIdentifier("editor.retryLoadButton")
            Button("Back to files", action: backTapped)
                .accessibilityIdentifier("editor.loadBackButton")
        }
    }
}
