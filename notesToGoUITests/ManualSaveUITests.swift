import XCTest

/// Run on iPad: the editor toolbar and finger-drawing canvas must be visible.
final class ManualSaveUITests: BaseUITestCase {
    private var saveButton: XCUIElement { app.app.buttons["editor.saveButton"] }
    private var addPageButton: XCUIElement { app.app.buttons["editor.addPageButton"] }
    private var saveProgress: XCUIElement {
        app.app.activityIndicators["editor.saveProgress"]
    }

    func test_cleanNote_opensWithSaveDisabled() {
        let name = createNote(saveMode: "delayed")
        thenSaveIsClean()

        // Loading an existing note, not just creating one, starts clean.
        relaunchAndOpenNote(named: name)
        thenSaveIsClean()
    }

    func test_addingPage_enablesSave_andSavingBlocksPageEditsWithoutClosing() {
        _ = createNote(saveMode: "delayed")
        thenSaveIsClean()
        addPageButton.tap()
        thenSaveIsEnabled()

        saveButton.tap()
        thenSaveIsInFlight()
        thenSaveIsClean()
        app.editor.thenIsVisible()

        app.editor.openGrid()
        thenGridPageCountIs(2)
    }

    func test_gridEdits_areNotAutosaved_butExplicitSavePreservesThemAfterRelaunch() {
        let name = createNote(saveMode: "delayed")
        addPageInGridAndReturn()
        thenSaveIsEnabled()

        // Termination avoids the editor's close/save lifecycle entirely.
        relaunchAndOpenNote(named: name)
        thenSaveIsClean()
        app.editor.openGrid()
        thenGridPageCountIs(1)
        app.grid.done()

        addPageInGridAndReturn()
        thenSaveIsEnabled()
        saveButton.tap()
        thenSaveIsInFlight()
        thenSaveIsClean()

        relaunchAndOpenNote(named: name)
        thenSaveIsClean()
        app.editor.openGrid()
        thenGridPageCountIs(2)
    }

    func test_failedSave_keepChanges_allowsAnotherSaveWithoutLosingPages() {
        let name = createNote(saveMode: "failOnce")
        addPageButton.tap()
        thenSaveIsEnabled()
        saveButton.tap()
        thenSaveIsInFlight()

        let alert = saveFailureAlert()
        alert.buttons["Keep changes"].tap()
        waitUntil("Save failure is dismissed") { !alert.exists }
        thenSaveIsEnabled()
        XCTAssertTrue(addPageButton.isEnabled)
        XCTAssertFalse(saveProgress.exists)

        saveButton.tap()
        thenSaveIsInFlight()
        thenSaveIsClean()
        relaunchAndOpenNote(named: name)
        thenSaveIsClean()
        app.editor.openGrid()
        thenGridPageCountIs(2)
    }

    func test_failedSave_retryAlertAction_savesRetainedChanges() {
        let name = createNote(saveMode: "failOnce")
        addPageButton.tap()
        thenSaveIsEnabled()
        saveButton.tap()
        thenSaveIsInFlight()

        let alert = saveFailureAlert()
        alert.buttons["Retry"].tap()
        thenSaveIsInFlight()
        thenSaveIsClean()
        XCTAssertFalse(alert.exists)
        app.editor.thenIsVisible()

        relaunchAndOpenNote(named: name)
        thenSaveIsClean()
        app.editor.openGrid()
        thenGridPageCountIs(2)
    }

    func test_drawingOnVisiblePage_enablesSave_andSaveReturnsToClean() {
        app.app.launchEnvironment["NOTESTOGO_UI_TEST_DRAW_WITH_TOUCH"] = "1"
        _ = createNote(saveMode: "delayed")
        thenSaveIsClean()
        let canvas = app.editor.pagesScrollView
        waitUntil("Visible page canvas is ready for drawing") {
            canvas.exists && canvas.isHittable && canvas.frame.width > 100 && canvas.frame.height > 100
        }

        // A short horizontal stroke stays within the first visible page and does
        // not trigger the vertical bottom-overscroll add-page gesture.
        let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.35))
        let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.40))
        start.press(forDuration: 0.05, thenDragTo: end)
        thenSaveIsEnabled()

        // Ensure this was a markup edit, not an accidentally inserted page.
        app.editor.openGrid()
        thenGridPageCountIs(1)
        app.grid.done()
        thenSaveIsEnabled()
        saveButton.tap()
        thenSaveIsInFlight()
        thenSaveIsClean()
        app.editor.thenIsVisible()
    }

    @discardableResult
    private func createNote(saveMode: String) -> String {
        app.app.terminate()
        app.app.launchEnvironment["NOTESTOGO_UI_TEST_SAVE_MODE"] = saveMode
        app.launch()
        let name = "AT Manual Save \(UUID().uuidString.prefix(8))"
        app.explorer.createNote(named: name)
        app.editor.thenIsVisible()
        thenSaveIsClean()
        return name
    }

    private func relaunchAndOpenNote(named name: String) {
        app.app.terminate()
        app.launch()
        app.explorer.openNote(named: name)
        app.editor.thenIsVisible()
    }

    private func addPageInGridAndReturn() {
        app.editor.openGrid()
        thenGridPageCountIs(1)
        app.grid.addPage()
        thenGridPageCountIs(2)
        app.grid.done()
        app.editor.thenIsVisible()
    }

    private func thenGridPageCountIs(_ count: Int, file: StaticString = #filePath, line: UInt = #line) {
        app.grid.thenIsVisible(file: file, line: line)
        waitUntil("Grid contains \(count) pages", file: file, line: line) {
            self.app.grid.pageThumbnails.count == count
        }
    }

    private func thenSaveIsEnabled(file: StaticString = #filePath, line: UInt = #line) {
        waitUntil("Unsaved changes enable Save", file: file, line: line) {
            self.saveButton.exists && self.saveButton.isEnabled && self.saveButton.label == "Save"
        }
    }

    private func thenSaveIsInFlight(file: StaticString = #filePath, line: UInt = #line) {
        waitUntil("Saving shows progress and disables Save and Add Page", file: file, line: line) {
            self.saveButton.exists && !self.saveButton.isEnabled
                && self.saveButton.label == "Saving" && self.saveProgress.exists
                && self.addPageButton.exists && !self.addPageButton.isEnabled
        }
    }

    private func thenSaveIsClean(file: StaticString = #filePath, line: UInt = #line) {
        waitUntil("Clean editor disables Save and permits page edits", file: file, line: line) {
            self.saveButton.exists && !self.saveButton.isEnabled
                && self.saveButton.label == "Save"
                && self.addPageButton.exists && self.addPageButton.isEnabled
        }
    }

    private func saveFailureAlert(file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let alert = app.app.alerts["Couldn’t save note"]
        XCTAssertTrue(alert.waitForExistence(timeout: 8), file: file, line: line)
        XCTAssertTrue(alert.buttons["Keep changes"].exists, file: file, line: line)
        XCTAssertTrue(alert.buttons["Retry"].exists, file: file, line: line)
        XCTAssertFalse(saveProgress.exists, file: file, line: line)
        return alert
    }

    private func waitUntil(
        _ description: String,
        timeout: TimeInterval = 8,
        file: StaticString = #filePath,
        line: UInt = #line,
        condition: @escaping () -> Bool
    ) {
        let predicate = NSPredicate { _, _ in condition() }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        if result != .completed {
            let hierarchy = XCTAttachment(string: app.app.debugDescription)
            hierarchy.name = description
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
            let screenshot = XCTAttachment(screenshot: app.app.screenshot())
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
        XCTAssertEqual(result, .completed, description, file: file, line: line)
    }
}
