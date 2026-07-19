import XCTest

final class GridFlowUITests: BaseUITestCase {
    func test_reopeningGrid_keepsPageOrder() throws {
        let noteName = "AT Grid Order \(UUID().uuidString.prefix(8))"

        app.explorer.createNote(named: noteName)
        app.editor.thenIsVisible()

        app.editor.openGrid()
        app.grid.thenPageCountIs(1)

        app.grid.insertPage(afterPageAt: 0)
        app.grid.thenPageCountIs(2)
        app.grid.insertPage(afterPageAt: 1)
        app.grid.thenPageCountIs(3)
        app.grid.insertPage(afterPageAt: 2)
        app.grid.thenPageCountIs(4)

        let expectedOrder = app.grid.pageIDsInOrder()
        app.grid.done()

        app.editor.openGrid()
        app.grid.thenPageOrderIs(expectedOrder)
        app.grid.done()

        app.editor.openGrid()
        app.grid.thenPageOrderIs(expectedOrder)
        app.grid.done()
    }

    func test_gridAddPage_insertsPageAfterSelectedPage() throws {
        let noteName = "AT Grid Insert \(UUID().uuidString.prefix(8))"

        app.explorer.createNote(named: noteName)
        app.editor.thenIsVisible()

        app.editor.openGrid()
        app.grid.thenPageCountIs(1)

        app.grid.insertPage(afterPageAt: 0)
        app.grid.thenPageCountIs(2)

        app.grid.insertPage(afterPageAt: 0)
        app.grid.thenPageCountIs(3)
        
        app.grid.insertPage(afterPageAt: 1)
        app.grid.thenPageCountIs(4)
    }
}
