//
//  StressTestController.swift
//
//
//  Created by Filippo Lobisch on 08.02.23.
//

import Foundation

/// Class to represent a stress test controller instance used to load test this web server.
class StressTestController {
    /// The shared instance of the `StressTestController` class. Uses the singleton design pattern.
    static let shared = StressTestController()

    /// The terminal instance that will execute the load test command.
    let terminal = Terminal()

    /// Private initializer so each instance of the stress test controller is accessed through the shared instance.
    private init() {}

    /// Method that is used to execute the benchmark.
    /// It first finds the url for the `LoadTest.js` file and then runs the k6 command on the shell.
    func benchmark() {
        do {
            let loadTestPath = try LocalFileManager().url(forResource: "LoadTest", withExtension: "js")
            let command = "k6 run \(loadTestPath.path)"
            _ = try terminal.shell(command)
        } catch {
            print(error.localizedDescription)
        }
    }
}
