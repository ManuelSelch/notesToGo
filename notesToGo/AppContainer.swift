import SwiftUI
import Router

struct AppContainer: View {
    var body: some View {
        StackRouterView(MyRouter.shared, content: { route in
            VStack {
                switch route {
                case .explorer:
                    ExplorerContainer()
                case .editor:
                    EditorContainer()
                }
            }
        })
    }
}


#Preview {
    AppContainer()
}
