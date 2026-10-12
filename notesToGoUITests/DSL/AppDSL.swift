import XCTest

struct AppDSL {
    let app: XCUIApplication

    var explorer: ExplorerDSL { .init(app: app) }
    var editor: EditorDSL { .init(app: app) }
    var grid: GridDSL { .init(app: app) }

    init() {
        self.app = XCUIApplication()
        app.launchEnvironment["NOTESTOGO_UI_TEST_ID"] = UUID().uuidString
    }

    func cleanup() throws {
        app.terminate()
        // Do not seed fixtures or open the explorer during the cleanup launch.
        app.launchEnvironment.removeValue(forKey: "NOTESTOGO_UI_TEST_NOTE")
        app.launchEnvironment.removeValue(forKey: "NOTESTOGO_UI_TEST_MARKUP")
        app.launchEnvironment["NOTESTOGO_UI_TEST_MODE"] = "cleanup"
        defer { app.terminate() }
        app.launch()
        guard app.staticTexts["uitest.cleanupComplete"].waitForExistence(timeout: 10) else {
            throw CleanupError.didNotComplete
        }
    }

    private enum CleanupError: Error { case didNotComplete }

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
