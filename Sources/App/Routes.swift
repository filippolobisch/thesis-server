import Foundation
import Vapor

/// A structure object that configures the necessary HTTP routes for the server.
struct Routes {
    /// The adaptation controller instance. We use a property so that it is not re-created each time an adaptation is required.
    let adaptationController =  AdaptationController()

    /// The custom logger object used to write and store important messages of what is occuring.
    let logger = Logger.shared
    
    
    /// This method registers the required get and post http routes to the application.
    /// - Parameter app: The application that is running.
    func registerRoutes(app: Application) throws {
        app.get(use: index(request:))
        app.get("register", use: register(request:))
        app.post("execute", use: execute(request:))
        app.get("test", use: testCancelTaskLocal(request:))
        app.get("runTask", "outsideEU", use: runOutsideEUBackgroundTask(request:))
        app.get("runTask", "sensitiveData", use: runSensitiveDataBackgroundTask(request:))
        app.get("help", use: help(request:))
        app.get("saveLogs", use: saveLogToFile(request:))
        app.get("stress", use: stressTest(request:))

        try app.register(collection: TodoController())
    }

    /// The index page of this server.
    func index(request: Request) async throws -> String {
        return "Welcome to the thesis-server!"
    }

    /// The register API route that needs to be called to connect radar and this web server.
    func register(request: Request) async throws -> String {
        logger.add(message: "Attempting to register application on RADAR.")
        let app = request.application
        let result = try await adaptationController.registerThisAppOnRadar(app: app)
        if result != -1 {
            logger.add(message: "Registered application on RADAR.")
            return "Completed and successfully registered application on radar."
        } else {
            logger.add(message: "Error occurred when registering the application on RADAR.")
            return "An error occurred registering the application. Check radar for more information."
        }
    }

    /// API route to execute adaptations locally using hard-coded data. (Purely for testing purposes).
    func executeLocal(request: Request) -> Bool {
        let adapt = 1 // The adaptation to execute locally (1 for OutsideEU and 2 for SensitiveData).
        let data = "{ \"model\": \"test-local\", \"adaptations\": [\(adapt)]} "
        _ = adaptationController.root(data: data)
        print(adaptationController.outsideEU.task as Any)
        print(adaptationController.sensitiveData.task as Any)
        return true
    }

    /// 'POST' Route that receives an execute request. This route is primarily exposed to receive a body of the 'new' system model and the adaptations to execute.
    /// This is then passed to the root of the adaptation controller to handle decoding and taking the correct actions.
    func execute(request: Request) -> Bool {
        guard let data = request.body.string else {
            fatalError("Getting string from POST request failed")
        }

        let result = adaptationController.root(data: data)
        return result
    }

    /// Route that is used to stress test the server.
    /// Uses the terminal object to create a command using k6 and the `LoadTest.js` script.
    func stressTest(request: Request) -> Int {
        StressTestController.shared.benchmark()
        return StressTestController.shared.terminal.pid
    }

    /// Route that cancels any adaptation background task that is running. (Purely for testing purposes).
    func testCancelTaskLocal(request: Request) -> Bool {
        adaptationController.outsideEU.cancelTask()
        adaptationController.sensitiveData.cancelTask()
        print(adaptationController.outsideEU.task as Any)
        print(adaptationController.sensitiveData.task as Any)
        return true
    }

    /// Route that runs the outsideEU adaptation background task.
    /// Used primarily for testing purposes, however, can be called if the outsideEU background task should be started before any adaptation occurs.
    func runOutsideEUBackgroundTask(request: Request) -> Bool {
        logger.add(message: "Start the outsideEU getFilesConstantly task.")
        adaptationController.outsideEU.getFilesConstantly()
        logger.add(message: "Started the outsideEU getFilesConstantly task.")
        return true
    }

    /// Route that runs the sensitiveData adaptation background task.
    /// Used primarily for testing purposes, however, can be called if the sensitiveData background task should be started before any adaptation occurs.
    func runSensitiveDataBackgroundTask(request: Request) -> Bool {
        logger.add(message: "Start the sensitive data getFilesConstantly task.")
        adaptationController.sensitiveData.getFilesConstantly()
        logger.add(message: "Started the sensitive data getFilesConstantly task.")
        return true
    }

    /// Route that cancels any adaptation background task that is running.
    /// Used primarily for testing purposes, however, can be called if a background task requires cancellation.
    func cancelRunningBackgroundTask(request: Request) -> Bool {
        adaptationController.outsideEU.cancelTask()
        adaptationController.sensitiveData.cancelTask()
        logger.add(message: "Cancelled the running background tasks.")
        return true
    }

    /// Route that saves the logs to the local `data_files` directory.
    func saveLogToFile(request: Request) -> String {
        logger.saveLogs()
        return "Saved logs."
    }

    /// Help route that shows all the possible HTTP calls that can be made on this server.
    /// Useful if someone does not know of the functionality included in this server.
    func help(request: Request) -> String {
        let app = request.application
        return app.routes.all.description
    }
}
