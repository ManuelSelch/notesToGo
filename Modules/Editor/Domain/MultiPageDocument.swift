import SwiftUI
import PaperKit
import PencilKit

/// document that stores multiple pages
struct MultiPageDocument: Equatable {
    var pages: [Page] = []
    
    init(pages: [Page] = []) {
        self.pages = pages
    }
    
    init(pageCount: Int = 1, template: @autoclosure () -> Page) {
        for _ in 0..<pageCount {
            pages.append(template())
        }
    }
    
    mutating func addPage(_ page: Page) {
        pages.append(page)
    }
    
    static var empty = MultiPageDocument(
        pageCount: 1,
        template: .empty
    )
}

// MARK: - encode & decode
extension MultiPageDocument: Codable {
    struct PageDTO: Codable {
        let id: UUID
        let markupData: Data
        let background: PageBackground
    }
    
    private enum CodingKeys: String, CodingKey {
        case pages
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dtos = try container.decode([PageDTO].self, forKey: .pages)
        pages = try dtos.map { dto in
            let markup = try PaperMarkup(dataRepresentation: dto.markupData)
            return Page(id: dto.id, markup: markup, background: dto.background)
        }
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
            PageDTO(id: page.id, markupData: data, background: page.background)
        }
        try container.encode(dtos, forKey: .pages)
    }
}
