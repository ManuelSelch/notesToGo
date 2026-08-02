import Foundation
import Flux
import PaperKit

nonisolated struct EditorFeature: Feature {
    struct State: Equatable, Sendable {
        var note: Note?
        var document: MultiPageDocument?
        
        var isLoading = false
        var mode: EditMode = .read
        
        var penSize: CGFloat = 1
        var defaultColor: CodableColor = .black
        
        var selectedTool: PencilTool = .pen(1, .black)
        var previousInkTool: PencilTool = .pen(1, .black)
        
        var copiedPage: Page?
    }
    
    enum Action: Equatable, Sendable {
        // MARK: - document
        case openNote(Note)
        case openQuickNote(Note)
        case documentLoaded(MultiPageDocument)
        case addPageTapped
        case pageAppended(Page)
        case insertPageTapped(after: UUID?)
        case pageInserted(after: UUID?, page: Page)
        case movePage(source: UUID, destination: UUID)
        case copyPage(UUID)
        case pastePageTapped(after: UUID?)
        case pagePasted(after: UUID?, page: Page)
        
        // MARK: - save
        case save([UUID:PaperMarkup])
        case saved
        case savedFailed
        
        // MARK: - mode
        case toggleEditMode
        case toggleFocusMode
        
        // MARK: - tool
        case penSizeChanged(CGFloat)
        case toolSelected(PencilTool)
        case pencilDoubleTap
        
        case selectedColorChanged(CodableColor)
        case defaultColorChanged(CodableColor)
    }
    
    enum Route: RouteType {
        /// main editor screen to read & write
        case editor
        
        /// page grid to rearrange, copy, and insert pages
        case grid
        
        var id: Self { self }
    }
}
