import Foundation
import Vapor

/// A structure object that configures the necessary HTTP routes for the server.
struct Routes {
    
    /// The adaptation controller instance. We use a property so that it is not re-created each time an adaptation is required.
    let adaptationController =  AdaptationController.shared

    /// The custom logger object used to write and store important messages of what is occurring.
    let logger = Logger.shared
    
    
    /// This method registers the required get and post http routes to the application.
    /// - Parameter app: The application that is running.
    func registerRoutes(app: Application) throws {
        app.get(use: index(request:))
        app.get("runExperiment", use: runExperiment(request:))
        app.get("register", use: register(request:))
    }

    /// The index page of this server.
    func index(request: Request) -> String {
        return "Welcome to the thesis-server!"
    }
    
    func runExperiment(request: Request) -> Bool {
        guard let data = request.body.string else {
            fatalError("Getting string from POST request failed")
        }

        return adaptationController.root(data: data)
    }

    /// The register API route that needs to be called to connect radar and this web server.
    func register(request: Request) async throws -> String {
        logger.add(message: "Attempting to register application on RADAR.")
        let result = try await RadarController().registerThisAppOnRadar(app: request.application)
        if result != -1 {
            logger.add(message: "Registered application on RADAR.")
            return "Completed and successfully registered application on radar."
        } else {
            logger.add(message: "Error occurred when registering the application on RADAR.")
            return "An error occurred registering the application. Check radar for more information."
        }
    }
}
