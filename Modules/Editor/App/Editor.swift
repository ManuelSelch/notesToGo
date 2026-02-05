import Foundation
import PaperKit
import PencilKit

@Observable
class Editor {
    let controller: MultiPageController
    
    init() {
        controller = MultiPageController()
    }
    
    func initialize(_ document: MultiPageDocument) {
        controller.document = document
    }
    
    func addPage() {
        controller.addNewPage()
    }
    
    /// show or hide native pencil tools
    func showPencilTools(_ isVisible: Bool) {
        controller.showPencilTools(isVisible)
    }
}
