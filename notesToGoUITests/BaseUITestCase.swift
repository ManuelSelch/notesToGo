import XCTest

class BaseUITestCase: XCTestCase {
    var app: AppDSL!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = AppDSL()
        let testApp = app!
        addTeardownBlock {
            try testApp.cleanup()
        }
        app.launch()
    }
}
