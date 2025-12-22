import SwiftUI

struct ExplorerContainer: View {
    @State var documents: [DocumentItem] = []
    
    let explorer = Explorer()
    
    var body: some View {
        NavigationStack {
            ExplorerView(documents: $documents)
                .onAppear {
                    self.documents = self.explorer.loadAllDocuments()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing, content: CreateToolbar)
                }
        }
    }
}

@ViewBuilder
func CreateToolbar() -> some View {
    Button(action: {}) {
        Image(systemName: "plus")
    }
}

#Preview {
    ExplorerContainer()
}
