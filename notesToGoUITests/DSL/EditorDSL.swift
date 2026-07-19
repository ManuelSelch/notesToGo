import XCTest

struct EditorDSL {
    let app: XCUIApplication

    var closeButton: XCUIElement { app.buttons["editor.closeButton"] }
    var openGridButton: XCUIElement { app.buttons["editor.openGridButton"] }
    var pagesScrollView: XCUIElement { app.scrollViews["editor.pagesScrollView"] }
    var currentPageIndicator: XCUIElement { app.otherElements["editor.currentPageIndicator"] }
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

    func openGrid(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(openGridButton.waitForExistence(timeout: 2), file: file, line: line)
        openGridButton.tap()
    }

    func scrollToBottom(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(pagesScrollView.waitForExistence(timeout: 2), file: file, line: line)
        
        for _ in 0..<5 {
            pagesScrollView.swipeUp()
        }
        
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
    }
    
    func dragPage(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(pagesScrollView.waitForExistence(timeout: 2), file: file, line: line)
        
        let start = pagesScrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        let end = pagesScrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        start.press(forDuration: 0.01, thenDragTo: end)

        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
    }

    func thenCurrentPageIs(_ expectedPage: Int, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(currentPageIndicator.waitForExistence(timeout: 2), file: file, line: line)

        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if let value = currentPageIndicator.value as? String, value == String(expectedPage) {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        XCTAssertEqual(currentPageIndicator.value as? String, String(expectedPage), file: file, line: line)
    }

    func scrollUntilCurrentPageIs(_ expectedPage: Int, maxSwipes: Int = 6, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(pagesScrollView.waitForExistence(timeout: 2), file: file, line: line)

        for _ in 0..<maxSwipes {
            if let value = currentPageIndicator.value as? String, value == String(expectedPage) {
                return
            }
            pagesScrollView.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        }

        thenCurrentPageIs(expectedPage, file: file, line: line)
    }

    func close(file: StaticString = #filePath, line: UInt = #line) {
        thenIsVisible(file: file, line: line)
        closeButton.tap()
    }
}
