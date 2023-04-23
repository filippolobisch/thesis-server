//
//  LoggerTests.swift
//  
//
//  Created by Filippo Lobisch on 12.02.23.
//

import Foundation
import XCTest
@testable import App

/// The test class that handles all the test cases for the `Logger` object.
final class LoggerTests: XCTestCase {
    /// Tests the addition of a message to the logs.
    func testAddLogMessage() throws {
        let logger = Logger()
        let logMessage = "This is the expected log message."
        logger.add(message: logMessage)
        let expectation = "\(Date())\t\(logMessage)"
        
        XCTAssertEqual(logger.logs, expectation, "The retrieved log was expected to be equal to the expectation, however, they do not equate.")
    }
}
