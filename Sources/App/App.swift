import Foundation
import Vapor
import Fluent
import FluentPostgresDriver


@main
public struct App {
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
