@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    func testGreeting() throws {
        let app = App.testing()
        defer { app.shutdown() }

        try app.test(.GET, "", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "It works!")
        })
    }
}
