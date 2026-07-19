import SwiftUI
import PaperKit
import UniformTypeIdentifiers

// MARK: - Grid View
struct GridScreen: View {
    let pages: [Page]
    let hasCopiedPage: Bool
    let onAddPage: (UUID?) -> Void
    let onCopyPage: (UUID) -> Void
    let onPastePage: (UUID?) -> Void
    let onMovePage: (UUID, UUID) -> Void
    let onDone: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 16)]
    private let thumbnailSize = CGSize(width: 220, height: 320)

    @State private var selectedPageID: UUID?
    @State private var draggedPageID: UUID?

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        PageThumbnailView(
                            page: page,
                            pageIndex: index,
                            thumbnailSize: thumbnailSize,
                            isSelected: selectedPageID == page.id
                        )
                        .accessibilityElement(children: .ignore)
                        .accessibilityIdentifier("editor.grid.page.\(page.id.uuidString)")
                        .accessibilityLabel("Page \(index + 1)")
                        .accessibilityValue(selectedPageID == page.id ? "selected" : "not_selected")
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPageID = page.id
                        }
                        .onDrag {
                            draggedPageID = page.id
                            return NSItemProvider(object: page.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: PageDropDelegate(
                                targetPageID: page.id,
                                draggedPageID: $draggedPageID,
                                onMovePage: onMovePage
                            )
                        )
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Pages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack {
                    Button {
                        onAddPage(selectedPageID)
                    } label: {
                        Label("Add", systemImage: "plus.rectangle.portrait")
                    }
                    .accessibilityIdentifier("editor.grid.addPageButton")
                    
                    Button {
                        guard let selectedPageID else { return }
                        onCopyPage(selectedPageID)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .disabled(selectedPageID == nil)
                    
                    Button {
                        onPastePage(selectedPageID)
                    } label: {
                        Label("Paste", systemImage: "clipboard")
                    }
                    .disabled(!hasCopiedPage)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done", action: onDone)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("editor.grid.doneButton")
            }
        }
        .onAppear {
            selectedPageID = selectedPageID ?? pages.first?.id
        }
        .onChange(of: pages.map(\.id)) {
            if let selectedPageID, !pages.contains(where: { $0.id == selectedPageID }) {
                self.selectedPageID = pages.first?.id
            } else if self.selectedPageID == nil {
                self.selectedPageID = pages.first?.id
            }
        }
    }
}

private struct PageDropDelegate: DropDelegate {
    let targetPageID: UUID
    @Binding var draggedPageID: UUID?
    let onMovePage: (UUID, UUID) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggedPageID, draggedPageID != targetPageID else { return }
        onMovePage(draggedPageID, targetPageID)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedPageID = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

#Preview {
    GridScreen(
        pages: Array(repeating: Page.empty, count: 8),
        hasCopiedPage: true,
        onAddPage: { _ in },
        onCopyPage: { _ in },
        onPastePage: { _ in },
        onMovePage: { _, _ in },
        onDone: {}
    )
}
