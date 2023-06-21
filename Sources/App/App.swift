import Foundation
import Vapor

/// The main starting point of the application.
/// This is the entry point of the web server when either the run button in Xcode is pressed or `swift run` command is used in the terminal.
/// This is denoted by the `@main` attribute attached to the App struct and the `public static fun main()` method.
@main
struct App {
    /// The main method of the application.
    /// Called when the program starts via either run button on Xcode or `swift run` command.
    /// Detects the environment that its running, and creates an Application object using the aforementioned environment.
    /// Set-ups the routes of the server and runs the application.
    static func main() throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = Application(env)
        defer { app.shutdown() }
        
        app.http.client.configuration.timeout = .init(connect: .seconds(60), read: .seconds(60))

        try Routes().registerRoutes(app: app)
        try app.run()
    }
}
