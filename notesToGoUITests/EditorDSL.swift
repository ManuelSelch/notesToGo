import XCTest

struct EditorDSL {
    let app: XCUIApplication

    var closeButton: XCUIElement { app.buttons["editor.closeButton"] }
    var enterFocusModeButton: XCUIElement { app.buttons["editor.enterFocusModeButton"] }
    var exitFocusModeButton: XCUIElement { app.buttons["editor.exitFocusModeButton"] }

    func thenIsVisible(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5), file: file, line: line)
    }

    func thenIsInWriteMode(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(enterFocusModeButton.waitForExistence(timeout: 2), file: file, line: line)
    }

    func thenIsInFocusMode(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(exitFocusModeButton.waitForExistence(timeout: 2), file: file, line: line)
    }

    func enterFocusMode(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(enterFocusModeButton.waitForExistence(timeout: 2), file: file, line: line)
        enterFocusModeButton.tap()
    }

    func exitFocusMode(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(exitFocusModeButton.waitForExistence(timeout: 2), file: file, line: line)
        exitFocusModeButton.tap()
    }

    func close(file: StaticString = #filePath, line: UInt = #line) {
        thenIsVisible(file: file, line: line)
        closeButton.tap()
    }
}
