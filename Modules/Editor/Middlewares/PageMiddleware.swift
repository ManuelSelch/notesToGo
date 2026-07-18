import Foundation
import Flux

class PageMiddleware {
    init() {}
    
    func handle(state: EditorFeature.State, action: EditorFeature.Action) async -> EditorFeature.Action? {
        switch action {
        case .addPageTapped:
            return .pageAppended(.empty(id: UUID()))
            
        case let .insertPageTapped(after: pageID):
            return .pageInserted(after: pageID, page: .empty(id: UUID()))
            
        case let .pastePageTapped(after: pageID):
            guard let copiedPage = state.copiedPage else { return .none }
            return .pagePasted(after: pageID, page: copiedPage.duplicated(id: UUID()))
            
        default:
            return .none
        }
    }
}
