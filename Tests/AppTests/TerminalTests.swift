//
//  TerminalTests.swift
//  
//
//  Created by Filippo Lobisch on 08.02.23.
//

import Foundation
import XCTest
@testable import App

/// The test class that handles all the test cases for the `Terminal` object.
final class TerminalTests: XCTestCase {
    /// Test the execution of a command.
    func testCommandExecuted() throws {
        let terminal = Terminal()
        let command = "ls"
        XCTAssertNoThrow(try terminal.shell(command), "The execution of the shell method inside the terminal class was expected to not throw an error, however, an error was thrown.")
    }
    
    /// Test the termination of a process.
    func testTerminateProcess() throws {
        let terminal = Terminal()
        let command = "ls"
        try terminal.shell(command)
        
        let expectedProcessID = -1000
        XCTAssertNotEqual(terminal.pid, expectedProcessID, "The process id (\(terminal.pid)) was expected to be different than the expected process id (\(expectedProcessID)), however, they are equal.")
        
        let terminationResult = try terminal.terminate()
        XCTAssertEqual(terminal.pid, expectedProcessID, "The terminal process id was expected to be equal to the expected process id (\(expectedProcessID)), however, their values are different.")
        XCTAssertTrue(terminationResult, "The termination result was expected to be true, however, it is false.")
    }
}
