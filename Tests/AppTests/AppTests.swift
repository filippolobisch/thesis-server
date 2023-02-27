@testable import App
import XCTVapor

/// The test class that handles all the test cases for the `AppTests` object.
final class AppTests: XCTestCase {
    
    ///
    func testGreeting() throws {
        let app = try App.testing()
        defer { app.shutdown() }

        try app.test(.GET, "", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "Welcome to the thesis-server!")
        })
    }
}
