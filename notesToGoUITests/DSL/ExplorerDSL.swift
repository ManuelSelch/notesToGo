import XCTest

struct ExplorerDSL {
    let app: XCUIApplication

    var createNoteButton: XCUIElement { app.buttons["explorer.createNoteButton"] }
    var createFolderButton: XCUIElement { app.buttons["explorer.createFolderButton"] }
    var noteNameField: XCUIElement { app.textFields["explorer.createNote.nameField"] }
    var folderNameField: XCUIElement { app.textFields["explorer.createFolder.nameField"] }
    var confirmCreateNoteButton: XCUIElement { app.buttons["explorer.createNote.confirmButton"] }
    var confirmCreateFolderButton: XCUIElement { app.buttons["explorer.createFolder.confirmButton"] }
    var backButton: XCUIElement { app.buttons["explorer.backButton"] }

    func createNote(named name: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(createNoteButton.waitForExistence(timeout: 2), file: file, line: line)
        createNoteButton.tap()

        XCTAssertTrue(noteNameField.waitForExistence(timeout: 2), file: file, line: line)
        noteNameField.tap()
        noteNameField.typeText(name)

        XCTAssertTrue(confirmCreateNoteButton.isEnabled, file: file, line: line)
        confirmCreateNoteButton.tap()
    }

    func createFolder(named name: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(createFolderButton.waitForExistence(timeout: 2), file: file, line: line)
        createFolderButton.tap()

        XCTAssertTrue(folderNameField.waitForExistence(timeout: 2), file: file, line: line)
        folderNameField.tap()
        folderNameField.typeText(name)

        XCTAssertTrue(confirmCreateFolderButton.isEnabled, file: file, line: line)
        confirmCreateFolderButton.tap()
    }

    func openNote(named name: String, file: StaticString = #filePath, line: UInt = #line) {
        let note = app.buttons["explorer.note.\(name)"]
        XCTAssertTrue(note.waitForExistence(timeout: 2), file: file, line: line)
        note.tap()
    }

    func openFolder(named name: String, file: StaticString = #filePath, line: UInt = #line) {
        let folder = app.buttons["explorer.folder.\(name)"]
        XCTAssertTrue(folder.waitForExistence(timeout: 2), file: file, line: line)
        folder.tap()
    }

    func goBack(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(backButton.waitForExistence(timeout: 2), file: file, line: line)
        backButton.tap()
    }

    func thenNoteIsVisible(named name: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            app.buttons["explorer.note.\(name)"].waitForExistence(timeout: 2),
            file: file,
            line: line
        )
    }

    func thenFolderIsVisible(named name: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            app.buttons["explorer.folder.\(name)"].waitForExistence(timeout: 2),
            file: file,
            line: line
        )
    }
}
