import XCTest

final class StorageIsolationUITests: BaseUITestCase {
    func test_noteSurvivesRelaunch_butNotANewTestID_andCleanupRemovesIt() throws {
        let name = "AT Isolation"
        app.explorer.createNote(named: name)
        app.editor.thenIsVisible()
        app.editor.close()
        app.app.terminate()
        app.launch()
        app.explorer.thenNoteIsVisible(named: name)

        let isolatedApp = AppDSL()
        addTeardownBlock { try isolatedApp.cleanup() }
        app.app.terminate()
        isolatedApp.launch()
        XCTAssertTrue(isolatedApp.explorer.createNoteButton.waitForExistence(timeout: 5))
        XCTAssertFalse(isolatedApp.app.buttons["explorer.note.\(name)"].exists)
        isolatedApp.app.terminate()

        // Reusing the original ID after acknowledged cleanup starts empty.
        try app.cleanup()
        app.app.launchEnvironment.removeValue(forKey: "NOTESTOGO_UI_TEST_MODE")
        app.launch()
        XCTAssertTrue(app.explorer.createNoteButton.waitForExistence(timeout: 5))
        XCTAssertFalse(app.app.buttons["explorer.note.\(name)"].exists)
    }
}
