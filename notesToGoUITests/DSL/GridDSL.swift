import XCTest

struct GridDSL {
    let app: XCUIApplication

    var doneButton: XCUIElement { app.buttons["editor.grid.doneButton"] }
    var addPageButton: XCUIElement { app.buttons["editor.grid.addPageButton"] }
    var pageThumbnails: XCUIElementQuery {
        app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH %@", "editor.grid.page."))
    }

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

    func selectPage(at index: Int, file: StaticString = #filePath, line: UInt = #line) {
        let page = pageThumbnails.element(boundBy: index)
        XCTAssertTrue(page.waitForExistence(timeout: 2), file: file, line: line)
        page.tap()
    }

    func addPage(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(addPageButton.waitForExistence(timeout: 2), file: file, line: line)
        addPageButton.tap()
    }

    
    func insertPage(afterPageAt selectedIndex: Int, file: StaticString = #filePath, line: UInt = #line) {
        let previousOrder = pageIDsInOrder()
        selectPage(at: selectedIndex)
        addPage()
        thenPageInserted(afterPageAt: selectedIndex, previousOrder: previousOrder, file: file, line: line)
    }
    
    private func thenPageInserted(afterPageAt selectedIndex: Int, previousOrder: [String], file: StaticString = #filePath, line: UInt = #line) {
        let after = pageIDsInOrder()

        XCTAssertEqual(after.count, previousOrder.count + 1, file: file, line: line)

        let expectedBefore = Array(previousOrder.prefix(selectedIndex + 1))
        let expectedAfter = Array(previousOrder.dropFirst(selectedIndex + 1))

        XCTAssertEqual(Array(after.prefix(selectedIndex + 1)), expectedBefore, file: file, line: line)
        XCTAssertEqual(Array(after.dropFirst(selectedIndex + 2)), expectedAfter, file: file, line: line)

        let insertedID = after[selectedIndex + 1]
        XCTAssertFalse(previousOrder.contains(insertedID), file: file, line: line)
    }

    func pageIDsInOrder() -> [String] {
        pageThumbnails.allElementsBoundByIndex.compactMap { element in
            let prefix = "editor.grid.page."
            guard element.identifier.hasPrefix(prefix) else { return nil }
            return String(element.identifier.dropFirst(prefix.count))
        }
    }

    func thenPageOrderIs(_ expectedOrder: [String], file: StaticString = #filePath, line: UInt = #line) {
        thenIsVisible(file: file, line: line)

        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if pageIDsInOrder() == expectedOrder {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        XCTAssertEqual(pageIDsInOrder(), expectedOrder, file: file, line: line)
    }
    
    func done(file: StaticString = #filePath, line: UInt = #line) {
        thenIsVisible(file: file, line: line)
        doneButton.tap()
    }
}
