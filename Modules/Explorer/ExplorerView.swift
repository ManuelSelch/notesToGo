import SwiftUI

struct ExplorerView: View {
    @Binding var documents: [DocumentItem]

    var body: some View {
        NavigationView {
            List(documents) { doc in
                DocumentCard(doc)
                    .onTapGesture { openDocument(doc) }
            }
            .onAppear {
                documents = loadAllDocuments()
            }
        }
    }
    
    func openDocument(_ doc: DocumentItem) {
        // load PaperMarkup from doc.editableURL and open editor
    }
    
    func loadAllDocuments() -> [DocumentItem] {
        return []
    }
}

@ViewBuilder
func DocumentCard(_ doc: DocumentItem) -> some View {
    HStack {
        VStack(alignment: .leading) {
            Text(doc.name).font(.headline)
            Text(doc.modifiedDate, style: .date).font(.caption)
        }
        Spacer()
        if doc.exportedPDFURL != nil {
            Image(systemName: "doc.richtext")
        } else {
            Image(systemName: "pencil")
        }
    }
}

#Preview {
    ExplorerView(documents: .constant([
        .init(name: "ff", editableURL: .documentsDirectory, exportedPDFURL: nil, modifiedDate: .now)
    ]))
}
