import SwiftUI
import PaperKit

// MARK: - PageThumbnailView
struct PageThumbnailView: View {
    let markup: PaperMarkup
    let pageSize: CGSize
    let pageIndex: Int
    let thumbnailSize: CGSize

    @State private var image: UIImage?

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(radius: 2)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(4)
                } else {
                    ProgressView()
                }
            }
            .aspectRatio(pageSize.width / pageSize.height, contentMode: .fit)

            Text("\(pageIndex + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .task {
            if image == nil {
                image = await makeThumbnail(
                    markup: markup,
                    pageSize: pageSize,
                    thumbnailSize: thumbnailSize
                )
            }
        }
    }

    // MARK: - Async Thumbnail Generator
    func makeThumbnail(
        markup: PaperMarkup,
        pageSize: CGSize,
        thumbnailSize: CGSize
    ) async -> UIImage {
        await MainActor.run {
            UIGraphicsBeginImageContextWithOptions(thumbnailSize, true, 0)
            defer { UIGraphicsEndImageContext() }

            guard let cg = UIGraphicsGetCurrentContext() else { return UIImage() }

            // Background
            UIColor.white.setFill()
            cg.fill(CGRect(origin: .zero, size: thumbnailSize))

            let scale = min(
                thumbnailSize.width / pageSize.width,
                thumbnailSize.height / pageSize.height
            )

            cg.saveGState()
            cg.scaleBy(x: scale, y: scale)

            let pageRect = CGRect(origin: .zero, size: pageSize)

            // ⚠️ async draw
            Task {
                await markup.draw(in: cg, frame: pageRect)
            }

            cg.restoreGState()

            return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        }
    }
}

// MARK: - GridView
struct GridView: View {
    let pages: [Page]
    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 16), count: 4)
    let thumbnailSize = CGSize(width: 200, height: 280)

    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 20) {
                ButtonWithIcon("Kopieren", icon: "doc.on.doc")
                ButtonWithIcon("Einfügen", icon: "clipboard")
                ButtonWithIcon("Teilen", icon: "square.and.arrow.up")
            }

            Spacer()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        PageThumbnailView(
                            markup: page.markup,
                            pageSize: .init(width: page.width, height: page.height),
                            pageIndex: index,
                            thumbnailSize: thumbnailSize
                        )
                        .frame(maxWidth: 150)
                    }
                }
                .padding()
            }
        }
        .padding()
    }

    @ViewBuilder
    func ButtonWithIcon(_ name: String, icon: String) -> some View {
        HStack(alignment: .center) {
            Image(systemName: icon)
            Text(name)
        }
    }
}

// MARK: - Preview
#Preview {
    let emptyPages = Array(repeating: Page.empty, count: 8)
    GridView(pages: emptyPages)
}
