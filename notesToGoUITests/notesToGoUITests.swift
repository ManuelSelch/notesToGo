import XCTest

final class notesToGoUITests: XCTestCase {
    var app: AppDSL!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = AppDSL()
        app.launch()
    }

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

    func test_focusModeRoundtrip_returnsToWriteMode() throws {
        let noteName = "AT Focus Note \(UUID().uuidString.prefix(8))"

        app.explorer.createNote(named: noteName)
        app.editor.thenIsVisible()
        app.editor.thenIsInWriteMode()

        app.editor.enterFocusMode()
        app.editor.thenIsInFocusMode()

        app.editor.exitFocusMode()
        app.editor.thenIsInWriteMode()
    }

    func test_overscrollInWriteMode_addsOnePage() throws {
        let noteName = "AT Overscroll One \(UUID().uuidString.prefix(8))"

        app.explorer.createNote(named: noteName)
        app.editor.thenIsVisible()
        app.editor.thenIsInWriteMode()

        app.editor.openGrid()
        app.grid.thenPageCountIs(1)
        app.grid.done()
        app.editor.thenIsVisible()

        app.editor.scrollToBottom()
        app.editor.dragPage()
        app.editor.openGrid()
        app.grid.thenPageCountIs(2)
    }

    func test_overscrollTwice_addsTwoPages() throws {
        let noteName = "AT Overscroll Two \(UUID().uuidString.prefix(8))"

        app.explorer.createNote(named: noteName)
        app.editor.thenIsVisible()
        app.editor.thenIsInWriteMode()

        app.editor.scrollToBottom()
        app.editor.dragPage()
        app.editor.dragPage()

        app.editor.openGrid()
        app.grid.thenPageCountIs(3)
    }

    func test_gridAddPage_insertsPageAfterSelectedPage() throws {
        let noteName = "AT Grid Insert \(UUID().uuidString.prefix(8))"

        app.explorer.createNote(named: noteName)
        app.editor.thenIsVisible()

        app.editor.openGrid()
        app.grid.thenPageCountIs(1)

        app.grid.insertPage(afterPageAt: 0)
        app.grid.thenPageCountIs(2)

        app.grid.insertPage(afterPageAt: 0)
        app.grid.thenPageCountIs(3)
        
        app.grid.insertPage(afterPageAt: 1)
        app.grid.thenPageCountIs(4)
    }
}
