//
//  Logger.swift
//
//
//  Created by Filippo Lobisch on 12.02.23.
//

import Foundation

/// Class to represent a Logger instance.
class Logger {
    /// The shared object of the logger.
    static let shared = Logger()
    
    /// The logs of the application.
    private(set) var logs = ""
    
    /// Adds a message to the full log.
    func add(message: String) {
        let newline = logs != "" ? "\n" : ""
        let newLog = "\(newline)\(Date())\t\(message)"
        logs.append(newLog)
    }
    
    /// Prints the logs to the command line.
    func printLogs() {
        print(logs)
    }
    
    /// Saves the logs to the local directory.
    func saveLogs() async {
        do {
            let logData = Data(logs.utf8)
            try await LocalManager().save(data: logData, toResource: "Log_\(Date())", withExtension: "log")
        } catch {
            print(error.localizedDescription)
        }
    }
}
