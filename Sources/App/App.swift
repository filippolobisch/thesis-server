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
        try registerRoutes(app: app)
        try app.run()
    }
    
    static func registerRoutes(app: Application) throws {
        app.get(use: Self.index)
        
        try app.register(collection: TodoController())
    }
    
    static func index(request: Request) async throws -> String {
        return "It works!"
    }
    
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
    
    static func testing() -> Application {
        let app = Application(.testing)
        configure(app: app)
        app.get("", use: Self.index)
        return app
    }
}
