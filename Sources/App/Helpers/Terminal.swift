//
//  Terminal.swift
//  
//
//  Created by Filippo Lobisch on 08.01.23.
//

import Foundation

/// Class to represent a terminal instance.
class Terminal {
    /// The path of the terminal executable to run the commands.
    private var urlPath: String {
        #if os(macOS)
        return "/bin/zsh"
        #else
        return "/bin/bash"
        #endif
    }
    
    private var zshURL: URL {
        URL(fileURLWithPath: urlPath)
    }
    
    /// The ID of the process that is running.
    private(set) var pid = -1000 // Since each terminal class results in one benchmark test we hold a single process ID that is later used to kill that process.
    // The PID is set to -1000 to begin with so that it does not refer to any process.
    
    /// Method used to execute one command on a terminal process which is attached to Xcode or the terminal which is executing the web server.
    /// This method creates a new process and uses the `-c` argument to execute the proper command.
    @discardableResult
    func shell(_ command: String) throws -> String {
        if pid > 1000 {
            try terminate()
        }
        
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.executableURL = zshURL
        process.arguments = ["-c", command]
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            pid = Int(process.processIdentifier)
            Logger.shared.add(message: "Started process with pid \(pid + 1).")
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(decoding: outputData, as: UTF8.self)
            return output
        } catch {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let error = String(decoding: errorData, as: UTF8.self)
            throw error
        }
    }
    
    /// Method used to execute multiple commands.
    /// This method takes a `String` array as a parameter using Swift variadic parameter syntax (i.e., can be passed by comma separation instead of an array object.
    /// With variadic parameters this method can be called `shell("cd ..", "ls -la")` instead of `shell(["cd Sources/App/", "ls -la"])`.
    /// This method joins all the commands with the separator `; ` which allows all commands to be typed in a single terminal command.
    /// Lastly this method calls the `shell(_ command: String)` listed above and returns the result received.
    @discardableResult
    func shell(_ commands: String...) throws -> String {
        let command = commands.joined(separator: "; ")
        return try shell(command)
    }
    
    /// Method to kill the running process.
    @discardableResult
    func terminate() throws -> Bool {
        let previousPID = pid + 1
        let process = try Process.run(zshURL, arguments: ["-c", "kill -9 \(pid + 1)"])
        process.waitUntilExit()
        pid = -1000
        Logger.shared.add(message: "Process with pid \(previousPID) terminated.")
        return true
    }
}
