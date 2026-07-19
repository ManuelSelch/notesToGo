import XCTest

struct AppDSL {
    let app: XCUIApplication

    var explorer: ExplorerDSL { .init(app: app) }
    var editor: EditorDSL { .init(app: app) }
    var grid: GridDSL { .init(app: app) }

    init() {
        self.app = XCUIApplication()
    }

    func launch() {
        app.launch()
    }

    func tapTopEdge() {
        if app.statusBars.firstMatch.exists {
            app.statusBars.firstMatch.tap()
            return
        }

        let topEdge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01))
        topEdge.tap()
        
        RunLoop.current.run(until: Date().addingTimeInterval(1.0))
    }
}
