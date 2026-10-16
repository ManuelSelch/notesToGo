import Foundation
import Flux
import PaperKit

nonisolated struct EditorFeature: Feature {
    struct State: Equatable, Sendable {
        var note: Note?
        var document: MultiPageDocument?
        
        var isLoading = false
        var loadFailure: OperationFailure?
        var saveFailure: OperationFailure?
        var hasUnsavedChanges = false
        var saveRequest: SaveRequest?
        var isSaving: Bool { saveRequest != nil }
        var canEditDocument: Bool { document != nil && !isLoading && !isSaving && loadFailure == nil }
        var canSave: Bool { note != nil && canEditDocument && hasUnsavedChanges }
        var mode: EditMode = .read
        
        var defaultTools: [PencilTool] = [ .pen(1, .black), .eraser, .lasso, .marker ]
        
        var tools: [PencilTool] = [ .pen(1, .black), .eraser, .lasso, .marker ]
        var selectedTool: PencilTool = .pen(1, .black)
        var previousInkTool: PencilTool = .pen(1, .black)
        
        var copiedPage: Page?
    }
    
    struct SaveRequest: Equatable, Sendable {
        let id: UUID
        let note: Note
        let document: MultiPageDocument
    }

    enum Action: Equatable, Sendable {
        // MARK: - document
        case openNote(Note)
        case openQuickNote(Note)
        case documentLoaded(MultiPageDocument)
        case documentLoadFailed(OperationFailure)
        case retryLoad
        case dismissLoadFailure
        case addPageTapped
        case pageAppended(Page)
        case insertPageTapped(after: UUID?)
        case pageInserted(after: UUID?, page: Page)
        case movePage(source: UUID, destination: UUID)
        case copyPage(UUID)
        case pastePageTapped(after: UUID?)
        case pagePasted(after: UUID?, page: Page)
        case canvasChanged(UUID)
        case captureMarkups([UUID: PaperMarkup])
        case pageBackgroundChanged(UUID, PageBackground)

        // MARK: - save
        case save([UUID: PaperMarkup], requestID: UUID = UUID())
        case saved(UUID)
        case savedFailed(UUID, OperationFailure)
        case dismissSaveFailure
        
        // MARK: - mode
        case toggleEditMode
        case toggleFocusMode
        
        // MARK: - tool
        case toolSelected(PencilTool)
        case pencilDoubleTap
        case defaultToolsChanged([PencilTool])
    }
    
    enum Route: RouteType {
        /// main editor screen to read & write
        case editor
        
        /// page grid to rearrange, copy, and insert pages
        case grid
        
        var id: Self { self }
    }
}
