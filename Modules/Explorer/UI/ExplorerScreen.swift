import SwiftUI

struct ExplorerScreen: View {
    let docs: [Document]
    
    let noteTapped: (Note) -> ()
    let folderTapped: (URL) -> ()
    
    let columns = [GridItem(.adaptive(minimum: 160), spacing: 18)]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(docs) { doc in
                    DocumentCard(doc)
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
        
    @ViewBuilder
    func DocumentCard(_ doc: Document) -> some View {
        switch doc {
        case .note(let note):
            Button(action: { noteTapped(note) }) {
                CardContent(
                    title: note.pdf.deletingPathExtension().lastPathComponent,
                    icon: "text.document.fill"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("explorer.note.\(note.pdf.deletingPathExtension().lastPathComponent)")
            
        case .folder(let folder):
            Button(action: { folderTapped(folder) }) {
                CardContent(
                    title: folder.lastPathComponent,
                    icon: "folder.fill"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("explorer.folder.\(folder.lastPathComponent)")
        }
    }
}

private struct CardContent: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 50, weight: .regular))
                .foregroundStyle(Color(uiColor: .systemBlue))
            
            VStack(spacing: 2) {
                Text(title)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    ExplorerScreen(
        docs: [
            .folder(.dummy("Folder A")),
            .note(.init(pdf: .dummy("File A.pdf"), markup: .dummy(".File A.markup"))),
            .folder(.dummy("Folder B")),
            .note(.init(pdf: .dummy("File B.pdf"), markup: .dummy(".File B.markup"))),
        ],
        
        noteTapped: { _ in },
        folderTapped: { _ in }
    )
}

extension URL {
    static func dummy(_ name: String) -> URL {
        URL(fileURLWithPath: name)
    }
}
