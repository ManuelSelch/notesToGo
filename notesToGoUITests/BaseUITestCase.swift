import XCTest

class BaseUITestCase: XCTestCase {
    var app: AppDSL!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = AppDSL()
        app.launch()
    }
}
