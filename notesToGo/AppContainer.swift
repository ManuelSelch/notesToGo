import SwiftUI
import Router

struct AppContainer: View {
    @StateObject var router = MyRouter.shared
    
    var body: some View {
        StackRouterView(router, content: { route in
            VStack {
                HStack {
                    Button("route", action: {
                        router.push(.test)
                    })
                }
                switch route {
                case .test:
                    Text("Test")
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
