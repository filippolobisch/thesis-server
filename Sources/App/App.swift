import Foundation
import Vapor

/// The main starting point of the application.
/// This is the entry point of the web server when either the run button in Xcode is pressed or `swift run` command is used in the terminal.
/// This is denoted by the `@main` attribute attached to the App struct and the `public static fun main()` method.
@main
public struct App {
    /// The main method of the application.
    /// Called when the program starts via either run button on Xcode or `swift run` command.
    /// Detects the environment that its running, and creates an Application object using the aforementioned environment.
    /// Set-ups the routes of the server and runs the application.
    /// Adds a logger message to signify the application start.
    public static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = Application(env)
        defer { app.shutdown() }

        let routes = Routes()
        try routes.registerRoutes(app: app)

        try app.run()
        routes.logger.add(message: "Application started.")
    }

    /// Method used for testing purposes, specifically in the AppTests.
    static func testing() throws -> Application {
        let app = Application(.testing)
        try Routes().registerRoutes(app: app)
        return app
    }
}
