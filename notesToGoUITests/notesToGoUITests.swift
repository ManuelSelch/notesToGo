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
}
