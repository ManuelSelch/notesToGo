import XCTest

struct ExplorerDSL {
    let app: XCUIApplication

    var createNoteButton: XCUIElement { app.buttons["explorer.createNoteButton"] }
    var noteNameField: XCUIElement { app.textFields["explorer.createNote.nameField"] }
    var confirmCreateNoteButton: XCUIElement { app.buttons["explorer.createNote.confirmButton"] }

    func createNote(named name: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(createNoteButton.waitForExistence(timeout: 2), file: file, line: line)
        createNoteButton.tap()

        XCTAssertTrue(noteNameField.waitForExistence(timeout: 2), file: file, line: line)
        noteNameField.tap()
        noteNameField.typeText(name)

        XCTAssertTrue(confirmCreateNoteButton.isEnabled, file: file, line: line)
        confirmCreateNoteButton.tap()
    }

    func thenNoteIsVisible(named name: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            app.buttons["explorer.note.\(name)"].waitForExistence(timeout: 2),
            file: file,
            line: line
        )
    }
}
