import SwiftUI
import Router
import Dependencies

struct AppContainer: View {
    @Dependency(\.router) var router
    
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
