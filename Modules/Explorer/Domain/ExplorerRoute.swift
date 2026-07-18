import Foundation

enum ExplorerRoute: RouteType {
    case dashboard(path: URL?)
    case createNoteSheet(path: URL?)
    case createFolderSheet(path: URL?)
    
    var id: Self { self }
}
