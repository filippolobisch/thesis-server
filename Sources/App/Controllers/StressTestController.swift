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
    
    let terminal = Terminal()
    
    private init() {}
    
    func httpBenchmark(users: Int) {
        #warning("Add the correct arguments for tsung.")
        let command = "tsung " // need to add the proper arguments to tsung.
        do {
            _ = try terminal.shell(command)
        } catch {
            print(error.localizedDescription)
        }
    }
}
