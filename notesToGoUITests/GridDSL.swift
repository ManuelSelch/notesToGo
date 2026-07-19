import XCTest

struct GridDSL {
    let app: XCUIApplication

    var doneButton: XCUIElement { app.buttons["editor.grid.doneButton"] }
    var pageThumbnails: XCUIElementQuery { app.otherElements.matching(identifier: "editor.grid.pageThumbnail") }

    func thenIsVisible(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(doneButton.waitForExistence(timeout: 2), file: file, line: line)
    }

    func thenPageCountIs(_ expectedCount: Int, file: StaticString = #filePath, line: UInt = #line) {
        thenIsVisible(file: file, line: line)

        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if pageThumbnails.count == expectedCount {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        XCTAssertEqual(pageThumbnails.count, expectedCount, file: file, line: line)
    }

    func done(file: StaticString = #filePath, line: UInt = #line) {
        thenIsVisible(file: file, line: line)
        doneButton.tap()
    }
}
