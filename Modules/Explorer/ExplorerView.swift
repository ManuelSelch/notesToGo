import SwiftUI

struct ExplorerView: View {
    @Binding var docs: [Document]
    
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
                    icon: "doc.text",
                    iconBackground: Color(uiColor: .tertiarySystemFill)
                )
            }
            .buttonStyle(.plain)
            
        case .folder(let folder):
            Button(action: { folderTapped(folder) }) {
                CardContent(
                    title: folder.lastPathComponent,
                    icon: "folder",
                    iconBackground: Color(uiColor: .tertiarySystemFill)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct CardContent: View {
    let title: String
    let icon: String
    let iconBackground: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(iconBackground)
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(.primary)
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
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
