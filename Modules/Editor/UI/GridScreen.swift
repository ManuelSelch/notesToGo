import SwiftUI
import PaperKit
import UniformTypeIdentifiers

// MARK: - Page Thumbnail
struct PageThumbnailView: View {
    let page: Page
    let pageIndex: Int
    let thumbnailSize: CGSize
    let isSelected: Bool

    @State private var image: UIImage?

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: page.background.backgroundColor))
                    .overlay {
                        if let pattern = page.background.patternImage() {
                            Image(uiImage: pattern)
                                .resizable(resizingMode: .tile)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: isSelected ? 3 : 1)
                    }
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                } else {
                    ProgressView()
                }
            }
            .aspectRatio(page.width / page.height, contentMode: .fit)

            Text("Page \(pageIndex + 1)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .task(id: page.id) {
            image = await makeThumbnail(page: page, thumbnailSize: thumbnailSize)
        }
    }

    @MainActor
    private func makeThumbnail(page: Page, thumbnailSize: CGSize) async -> UIImage {
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, 0)
        defer { UIGraphicsEndImageContext() }

        guard let cg = UIGraphicsGetCurrentContext() else { return UIImage() }

        let bounds = CGRect(origin: .zero, size: thumbnailSize)
        page.background.backgroundColor.setFill()
        cg.fill(bounds)

        if let pattern = page.background.patternImage() {
            UIColor(patternImage: pattern).setFill()
            cg.fill(bounds)
        }

        let scale = min(
            thumbnailSize.width / page.width,
            thumbnailSize.height / page.height
        )

        cg.saveGState()
        cg.scaleBy(x: scale, y: scale)
        await page.markup.draw(in: cg, frame: CGRect(origin: .zero, size: CGSize(width: page.width, height: page.height)))
        cg.restoreGState()

        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}

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
