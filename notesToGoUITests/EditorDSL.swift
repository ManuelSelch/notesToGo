import XCTest

struct EditorDSL {
    let app: XCUIApplication

    var closeButton: XCUIElement { app.buttons["editor.closeButton"] }

    func thenIsVisible(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5), file: file, line: line)
    }

    func close(file: StaticString = #filePath, line: UInt = #line) {
        thenIsVisible(file: file, line: line)
        closeButton.tap()
    }
}
