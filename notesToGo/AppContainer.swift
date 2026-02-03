import SwiftUI
import Router

struct AppContainer: View {

    
    var body: some View {
        StackRouterView(MyRouter.shared, content: { route in
            VStack {
                HStack {
                    Button("route", action: {
                        MyRouter.shared.push(.test)
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
