import XCTest

final class EditorFlowUITests: BaseUITestCase {
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
}
