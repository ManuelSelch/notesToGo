import XCTest

final class ExplorerFlowUITests: BaseUITestCase {
    func test_createNote_opensEditor_andAfterGoingBack_noteIsVisibleInExplorer() throws {
        let noteName = "AT Note \(UUID().uuidString.prefix(8))"

        app.explorer.createNote(named: noteName)
        app.editor.thenIsVisible()
        app.editor.close()

        app.explorer.thenNoteIsVisible(named: noteName)
    }

    func test_createFolder_andAfterGoingBack_folderIsVisibleInExplorer() throws {
        let folderName = "AT Folder \(UUID().uuidString.prefix(8))"

        app.explorer.createFolder(named: folderName)
        app.explorer.goBack()

        app.explorer.thenFolderIsVisible(named: folderName)
    }

    func test_openExistingNote_opensEditor() throws {
        let noteName = "AT Existing Note \(UUID().uuidString.prefix(8))"

        app.explorer.createNote(named: noteName)
        app.editor.thenIsVisible()
        app.editor.close()
        app.explorer.thenNoteIsVisible(named: noteName)

        app.explorer.openNote(named: noteName)
        app.editor.thenIsVisible()
    }
}
