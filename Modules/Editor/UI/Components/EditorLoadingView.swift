import SwiftUI

struct EditorLoadingView: View {
    let backTapped: () -> Void

    var body: some View {
        ProgressView("Opening note…")
            .toolbar {
                Button("Back to files", action: backTapped)
            }
    }
}
