import SwiftUI

struct ExplorerView: View {
    @Binding var docs: [Document]
    
    let noteTapped: (Note) -> ()
    let folderTapped: (URL) -> ()
    
    let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(docs) { doc in
                    DocumentCard(doc)
                }
            }
            .padding()
        }
    }
        
    @ViewBuilder
    func DocumentCard(_ doc: Document) -> some View {
        VStack(spacing: 8) {
                switch doc {
                case .note(let note):
                    Button(action: { noteTapped(note) }) {
                        Image(systemName: "doc.text")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                        Text(note.pdf.deletingPathExtension().lastPathComponent)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                case .folder(let folder):
                    Button(action: { folderTapped(folder) }) {
                        Image(systemName: "folder")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                        Text(folder.lastPathComponent)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding()
            .frame(minWidth: 120, minHeight: 120)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ExplorerView(
        docs: .constant([
            .folder(.dummy("Folder A")),
            .note(.init(pdf: .dummy("File A.pdf"), markup: .dummy(".File A.markup"))),
            .folder(.dummy("Folder B")),
            .note(.init(pdf: .dummy("File B.pdf"), markup: .dummy(".File B.markup"))),
        ]),
        
        noteTapped: { _ in },
        folderTapped: { _ in }
    )
}


extension URL {
    static func dummy(_ name: String) -> URL {
        URL(fileURLWithPath: name)
    }
}
