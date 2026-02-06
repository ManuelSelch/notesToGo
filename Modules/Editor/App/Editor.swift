import Foundation
import PaperKit
import PencilKit

@Observable
class Editor {
    let controller: MultiPageController
    let document: MultiPageDocument
    
    init(_ document: MultiPageDocument) {
        controller = MultiPageController()
        self.document = document
        
        self.controller.document = document
    }
    
    func addPage(with background: PageBackground = .plain(.white)) {
        let pageSize = CGSize(width: 90, height: 90) // 16:9 ratio
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
