import Foundation
import PaperKit
import PencilKit

@Observable
class Editor {
    let controller: MultiPageController
    var document: MultiPageDocument
    let fileURL: URL
    
    init(_ document: MultiPageDocument, fileURL: URL) {
        controller = MultiPageController()
        self.document = document
        self.fileURL = fileURL
        
        self.controller.document = document
    }
    
    func addPage(with background: PageBackground = .plain(.white)) {
        let pageSize = CGSize(width: 300, height: 500)
        let bounds = CGRect(origin: .zero, size: pageSize)
        let page = Page(bounds: bounds, background: background)
        
        document.addPage(page)
        controller.pageAdded()
    }
    
    /// show or hide native pencil tools
    func showPencilTools(_ isVisible: Bool) {
        controller.showPencilTools(isVisible)
    }
}

// MARK: - load & save
extension Editor {
    func save() async throws {
        controller.syncDrawingsToDocument()
        
        var markupDataList: [Data] = []
        for page in document.pages {
            markupDataList.append(try await page.markup.dataRepresentation())
        }
        
        let encoder = JSONEncoder()
        encoder.userInfo[.markupDataKey] = markupDataList
        let data = try encoder.encode(document)
        try data.write(to: fileURL, options: .atomic)
    }
    
    static func load(from fileURL: URL) throws -> Editor {
        let data = try Data(contentsOf: fileURL)
        let document = try JSONDecoder().decode(MultiPageDocument.self, from: data)
        return Editor(document, fileURL: fileURL)
    }
}

extension CodingUserInfoKey {
    static let markupDataKey = CodingUserInfoKey(rawValue: "markupData")!
}
