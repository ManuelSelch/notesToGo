import SwiftUI
import PaperKit

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
