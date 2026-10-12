import XCTest

final class ErrorFlowUITests: BaseUITestCase {
    func test_invalidName_showsError_andPreservesInputUntilCorrected() throws {
        let invalid = "../Invalid"
        let corrected = "AT Corrected \(UUID().uuidString.prefix(8))"
        app.explorer.createNote(named: invalid)

        let alert = app.app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.staticTexts["Couldn’t create note"].exists)
        alert.buttons["Edit name"].firstMatch.tap()

        XCTAssertEqual(app.explorer.noteNameField.value as? String, invalid)
        app.explorer.noteNameField.tap()
        app.explorer.noteNameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: invalid.count) + corrected)
        app.explorer.confirmCreateNoteButton.tap()

        app.editor.thenIsVisible()
        app.editor.close()
        app.explorer.thenNoteIsVisible(named: corrected)
    }

    func test_corruptNote_cannotBeEditedOrSaved_andOffersRetryAndBack() throws {
        try verifyFailedLoad(format: "corrupt", message: "The editable note data is damaged. Restore it from a backup and try again. Your files have not been changed.")
    }

    func test_unsupportedVersion_cannotBeEditedOrSaved_andOffersRetryAndBack() throws {
        try verifyFailedLoad(format: "unsupported", message: "Note format version 999 is not supported by this app. Your files have not been changed.")
    }

    private func verifyFailedLoad(format: String, message: String) throws {
        let name = "AT Error \(UUID().uuidString.prefix(8))"
        app.app.terminate()
        app.app.launchEnvironment["NOTESTOGO_UI_TEST_NOTE"] = name
        app.app.launchEnvironment["NOTESTOGO_UI_TEST_MARKUP"] = format
        app.launch()
        app.explorer.openNote(named: name)

        let errorTitle = app.app.staticTexts["Couldn’t open note"]
        XCTAssertTrue(errorTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(app.app.staticTexts[message].exists)
        XCTAssertFalse(app.editor.closeButton.exists)
        XCTAssertFalse(app.editor.openGridButton.exists)
        app.app.buttons["editor.retryLoadButton"].tap()
        XCTAssertTrue(errorTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(app.app.staticTexts[message].exists)
        app.app.buttons["editor.loadBackButton"].tap()
        app.explorer.thenNoteIsVisible(named: name)

        // Returning to the explorer did not save a blank replacement over the failed source.
        app.explorer.openNote(named: name)
        XCTAssertTrue(errorTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(app.app.staticTexts[message].exists)
        app.app.buttons["editor.loadBackButton"].tap()
    }

    func test_duplicateName_canRetryWithoutLosingName_orReplacingExistingNote() throws {
        let name = "AT Duplicate \(UUID().uuidString.prefix(8))"
        app.explorer.createNote(named: name)
        app.editor.thenIsVisible()
        app.editor.close()
        app.explorer.createNote(named: name)

        let alert = app.app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.staticTexts["A note with this name already exists. Choose another name and try again."].exists)
        alert.buttons["Retry"].firstMatch.tap()
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Edit name"].firstMatch.tap()
        XCTAssertEqual(app.explorer.noteNameField.value as? String, name)
        app.app.buttons["Cancel"].tap()
        app.explorer.thenNoteIsVisible(named: name)
    }
}
