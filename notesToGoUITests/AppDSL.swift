import XCTest

struct AppDSL {
    let app: XCUIApplication

    var explorer: ExplorerDSL { .init(app: app) }
    var editor: EditorDSL { .init(app: app) }

    init() {
        self.app = XCUIApplication()
    }

    func launch() {
        app.launch()
    }
}
