import Foundation
import Vapor
import Fluent
import FluentPostgresDriver

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
        configure(app: app)

        try app.run()
        routes.logger.add(message: "Application started.")
    }

    /// Method used for testing purposes, specifically in the AppTests.
    static func testing() throws -> Application {
        let app = Application(.testing)
        try Routes().registerRoutes(app: app)
        configure(app: app)
        return app
    }
}


// MARK: - The configuration methods needed for the app
extension App {
    static func configure(app: Application) {
        app.databases.use(.postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
            database: Environment.get("DATABASE_NAME") ?? "vapor_database"
        ), as: .psql)

        app.migrations.add(CreateTodo())
    }
}
