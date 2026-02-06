import SwiftUI
import PaperKit
import PencilKit


struct PageDTO: Codable {
    let markupData: Data
    let background: PageBackground
}

/// document that stores multiple pages
class MultiPageDocument: Codable {
    var pages: [Page] = []
    var currentPageIndex: Int = 0
    
    var currentPage: Page? {
        guard pages.indices.contains(currentPageIndex) else { return nil }
        return pages[currentPageIndex]
    }
    
    init(pageCount: Int = 1, pageSize: CGSize, background: PageBackground) {
        for _ in 0..<pageCount {
            pages.append(Page(bounds: CGRect(origin: .zero, size: pageSize), background: background))
        }
    }
    
    func addPage(_ page: Page) {
        pages.append(page)
    }
    
    func removePage(at index: Int) {
        guard pages.count > 1, pages.indices.contains(index) else { return }
        pages.remove(at: index)
        if currentPageIndex >= pages.count {
            currentPageIndex = pages.count - 1
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case pages, currentPageIndex
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dtos = try container.decode([PageDTO].self, forKey: .pages)
        pages = try dtos.map { dto in
            let markup = try PaperMarkup(dataRepresentation: dto.markupData)
            return Page(markup: markup, background: dto.background)
        }
        currentPageIndex = try container.decode(Int.self, forKey: .currentPageIndex)
    }

    func encode(to encoder: Encoder) throws {
        guard let markupDataList = encoder.userInfo[.markupDataKey] as? [Data] else {
            throw EncodingError.invalidValue(pages, .init(
                codingPath: [],
                debugDescription: "Markup data must be pre-serialized via userInfo"
            ))
        }

        var container = encoder.container(keyedBy: CodingKeys.self)
        let dtos = zip(pages, markupDataList).map { page, data in
            PageDTO(markupData: data, background: page.background)
        }
        try container.encode(dtos, forKey: .pages)
        try container.encode(currentPageIndex, forKey: .currentPageIndex)
    }
}
