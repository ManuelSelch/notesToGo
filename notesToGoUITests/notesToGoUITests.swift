import XCTest

final class notesToGoUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test_createNote_opensEditor_andAfterGoingBack_noteIsVisibleInExplorer() throws {
        let app = AppDSL()
        let noteName = "AT Note \(UUID().uuidString.prefix(8))"

        app.launch()

        app.explorer.createNote(named: noteName)
        app.editor.thenIsVisible()
        app.editor.close()

        app.explorer.thenNoteIsVisible(named: noteName)
    }

    @MainActor
    func test_createFolder_andAfterGoingBack_folderIsVisibleInExplorer() throws {
        let app = AppDSL()
        let folderName = "AT Folder \(UUID().uuidString.prefix(8))"

        app.launch()

        app.explorer.createFolder(named: folderName)
        app.explorer.goBack()

        app.explorer.thenFolderIsVisible(named: folderName)
    }

    @MainActor
    func test_openExistingNote_opensEditor() throws {
        let app = AppDSL()
        let noteName = "AT Existing Note \(UUID().uuidString.prefix(8))"

        app.launch()

        app.explorer.createNote(named: noteName)
        app.editor.thenIsVisible()
        app.editor.close()
        app.explorer.thenNoteIsVisible(named: noteName)

        app.explorer.openNote(named: noteName)
        app.editor.thenIsVisible()
    }

    @MainActor
    func test_focusModeRoundtrip_returnsToWriteMode() throws {
        let app = AppDSL()
        let noteName = "AT Focus Note \(UUID().uuidString.prefix(8))"

        app.launch()

        app.explorer.createNote(named: noteName)
        app.editor.thenIsVisible()
        app.editor.thenIsInWriteMode()

        app.editor.enterFocusMode()
        app.editor.thenIsInFocusMode()

        app.editor.exitFocusMode()
        app.editor.thenIsInWriteMode()
    }
}
