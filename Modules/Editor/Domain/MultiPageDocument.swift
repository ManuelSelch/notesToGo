import SwiftUI
import PaperKit
import PencilKit

/// document that stores multiple pages
struct MultiPageDocument: Equatable {
    var pages: [Page] = []
    var currentPageIndex: Int = 0
    
    var currentPage: Page? {
        guard pages.indices.contains(currentPageIndex) else { return nil }
        return pages[currentPageIndex]
    }
    
    init(pageCount: Int = 1, template: Page) {
        for _ in 0..<pageCount {
            pages.append(template)
        }
    }
    
    mutating func addPage(_ page: Page) {
        pages.append(page)
    }
    
    mutating func removePage(at index: Int) {
        guard pages.count > 1, pages.indices.contains(index) else { return }
        pages.remove(at: index)
        if currentPageIndex >= pages.count {
            currentPageIndex = pages.count - 1
        }
    }
    
    static var empty = MultiPageDocument(
        pageCount: 1,
        template: .empty
    )
}

// MARK: - encode & decode
extension MultiPageDocument: Codable {
    struct PageDTO: Codable {
        let markupData: Data
        let background: PageBackground
    }
    
    private enum CodingKeys: String, CodingKey {
        case pages, currentPageIndex
    }
    
    init(from decoder: Decoder) throws {
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
